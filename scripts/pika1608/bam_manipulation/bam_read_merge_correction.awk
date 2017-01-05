#!/bin/awk -f
#Needs a name sorted samfile as input!

#function to change the flag to a binary coding
function tobin(flag){
    r=""; 
    while(flag!=0){
        r=((flag%2)?"1":"0") r; 
        flag=int(flag/2);
    } 
    for(i=length(r); i<8; i++){
        r="0"r;
    } 
    return r;
}
#function return 0 if this read is mapped
function ismapped(binflag){
    split(binflag,arr,""); 
    if(arr[length(arr)-2]==1){
        return 0;
    }else{
        return 1;
    }
}
#function return 0 if pair read is mapped
function ismatemapped(binflag){
    split(binflag,arr,""); 
    if(arr[length(arr)-3]==1){
        return 0;
    }else{
        return 1;
    }
}
#function return 0 if this is the first read in the pair
function isfirst(binflag){
    split(binflag,arr,""); 
    if(arr[length(arr)-6]==1){
        return 0;
    }else{
        return 1;
    }
}
#function return 0 if this read is reverse on the reference genome
function isreverse(binflag){
    split(binflag,arr,""); 
    if(arr[length(arr)-4]==1){
        return 0;
    }else{
        return 1;
    }
}
#function to change the cigar string to a long version ex.: 5M becomes MMMMM
function longcigar(cigar){
    l=""; 
    split(cigar,arr,""); 
    b=""; 
    for(c=0;c<length(arr);c++){
        a=arr[c]; 
        if(a ~ /^[0-9]$/){
            b=b""a;
        }else{
            for(i=0;i<int(b);i++){
                l=l""a;
            }
            b="";
        }
    }
    return l;
}
#function to change the long cigar string to a normal one ex.: MMMMM becomes 5M
function shortcigar(cigar){
    s=""; 
    split(cigar,arr,""); 
    p=arr[1]; 
    c=1; 
    for(i=2;i<=length(arr);i++){
        a=arr[i]; 
        if(a==p){
            c++;
        }else{
            s=s""c""p; 
            c=1; 
            p=a;
        }
    } 
    s=s""c""p; 
    return s;
}
#function to print the line (obviously remain of development)
function printline(line){
    print line;
}
#the begin part
BEGIN{
    OFS="\t"
}
#the main script
{
    if($1 ~ "^@"){
        #is header
        printline($0);
        next;
    }
    binflag=tobin($2); 
    map=ismapped(binflag); 
    mate=ismatemapped(binflag); 
    if($2==0 || $2==16){
        #is flashed data
        printline($0);
        totalF+=1;
        flashF+=1;
    }else if($2==4){
        #unmapped flash data
        printline($0);
        totalF+=1;
        flashU+=1;
    }else if(map==0 || mate==0){
        #one of the mates is unmapped
        printline($0);
        totalF+=0.5;
        unmapped+=0.5;
    }else{
        split(prev,prevarr,"\t"); 
        if(prevarr[1]==$1){
            totalF+=1;
            #is same name as previous
            insert=$9;
            if(insert<0){insert=-insert}
            frag=length(prevarr[10])+length($10); 
            if(prevarr[3]==$3 && (prevarr[5]>6 && $5>6) && insert<=frag){
                #overlapping fragments
                if(isfirst(tobin($2))==0){
                    change=$0; 
                    $0=prev; 
                    prev=change;
                }
                lcigar=longcigar($6);
                clipl=frag-insert; 
                if(isreverse(tobin($2))==0){
                    ocigar=lcigar;
                    lcigar=substr(ocigar,clipl+1);
                    replace=substr(ocigar,0,clipl);
                    replace=gensub("D","","g",replace); 
                    for(i=0;i<length(replace);i++){
                        lcigar="S"lcigar;
                    }
                }else{
                    ocigar=lcigar;
                    lcigar=substr(ocigar,0,length(ocigar)-clipl);
                    replace=substr(ocigar,length(ocigar)-clipl+1);
                    replace=gensub("D","","g",replace); 
                    for(i=0;i<length(replace);i++){
                        lcigar=lcigar"S";
                    }
                }
                $6=shortcigar(lcigar); 
                printline(prev); 
                printline($0);
                corF+=1;
            }else{
                #non overlapping fragments
                printline(prev);
                printline($0);
            }
        }else{
            #is pair, but not same name as previous
            prev=$0;
        }
    }
}
#print some basic correction stats
END{
    print "Mapped flashed fragments: " flashF " ("(flashF/totalF)"%)" > "/dev/stderr";
    print "Unmapped flashed fragments: " flashU " ("(flashU/totalF)"%)" > "/dev/stderr";
    print "Unmapped: " unmapped " ("(unmapped/totalF)"%)" > "/dev/stderr";
    print "Corrected: " corF " ("(corF/totalF)"%)" > "/dev/stderr";
    print "Total: " totalF > "/dev/stderr";
}
