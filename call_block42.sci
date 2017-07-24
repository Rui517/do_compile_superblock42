function txt=call_block42(bk,pt,flag)
    txt=[]
    //**
    if flag==2 & ((zptr(bk+1)-zptr(bk))+..
        (ozptr(bk+1)-ozptr(bk))+..
        (xptr(bk+1)-xptr(bk)+..
        with_work(bk))==0 |..
        pt<=0) & ~(stalone & or(bk==actt(:,1))) then
        return // block without state or continuously activated
    end
    if flag==0 & ((xptr(bk+1)-xptr(bk))==0) then
        return // block without continuous state
    end
    if flag==9 & ((zcptr(bk+1)-zcptr(bk))==0) then
        return // block without continuous state
    end
    if flag==3 & ((clkptr(bk+1)-clkptr(bk))==0) then
        return
    end

    //** adjust pt
    if ~(flag==3 & ((zcptr(bk+1)-zcptr(bk))<>0)) then
        pt=abs(pt)
    end

    //** add comment
    txt=[txt;
    get_comment("call_blk",list(funs(bk),funtyp(bk),bk,labels(bk)));]

    //** set nevprt and flag for called block
    txt=[txt;
    "start_"+funs(bk)+"=clock()*1000;"
    "block_"+rdnom+"["+string(bk-1)+"].nevprt = "+string(pt)+";"
    "local_flag = "+string(flag)+";"]

    //**see if its bidon, actuator or sensor
    if funs(bk)=="bidon" then
        txt=[];
        return
    elseif funs(bk)=="bidon2" then
        txt=[];
        return
    elseif or(bk==actt(:,1)) then
        ind=find(bk==actt(:,1))
        uk=actt(ind,2)
        nuk_1=actt(ind,3)
        nuk_2=actt(ind,4)
        uk_t=actt(ind,5)
        txt = [txt;
        "nport = "+string(ind)+";"]
        txt = [txt;
        rdnom+"_actuator(&local_flag, &nport, &block_"+rdnom+"["+string(bk-1)+"].nevprt, \"
        get_blank(rdnom+"_actuator")+" &t, ("+mat2scs_c_ptr(outtb(uk))+" *)"+rdnom+"_block_outtbptr["+string(uk-1)+"], \"
        get_blank(rdnom+"_actuator")+" &nrd_"+string(nuk_1)+", &nrd_"+string(nuk_2)+", &nrd_"+string(uk_t)+",bbb);"]
        txt = [txt;
        "if(local_flag < 0) return(5 - local_flag);"
        "end_"+funs(bk)+"=clock();"
    "total_"+funs(bk)+"=(double)(end_"+funs(bk)+"-start_"+funs(bk)+");"]
        return
    elseif or(bk==capt(:,1)) then
        ind=find(bk==capt(:,1))
        yk=capt(ind,2);
        nyk_1=capt(ind,3);
        nyk_2=capt(ind,4);
        yk_t=capt(ind,5);
        txt = [txt;
        "nport = "+string(ind)+";"]
        txt = [txt;
        rdnom+"_sensor(&local_flag, &nport, &block_"+rdnom+"["+string(bk-1)+"].nevprt, \"
        get_blank(rdnom+"_sensor")+" &t, ("+mat2scs_c_ptr(outtb(yk))+" *)"+rdnom+"_block_outtbptr["+string(yk-1)+"], \"
        get_blank(rdnom+"_sensor")+" &nrd_"+string(nyk_1)+", &nrd_"+string(nyk_2)+", &nrd_"+string(yk_t)+",aaa);"]
        txt = [txt;
        "if(local_flag < 0) return(5 - local_flag);"
        "end_"+funs(bk)+"=clock();"
    "total_"+funs(bk)+"=(double)(end_"+funs(bk)+"-start_"+funs(bk)+");"]
        return
    end

    //**
    nx=xptr(bk+1)-xptr(bk);
    nz=zptr(bk+1)-zptr(bk);
    nrpar=rpptr(bk+1)-rpptr(bk);
    nipar=ipptr(bk+1)-ipptr(bk);
    nin=inpptr(bk+1)-inpptr(bk);  //* number of input ports */
    nout=outptr(bk+1)-outptr(bk); //* number of output ports */

    //**
    //l'adresse du pointeur de ipar
    if nipar<>0 then ipar=ipptr(bk), else ipar=1;end
    //l'adresse du pointeur de rpar
    if nrpar<>0 then rpar=rpptr(bk), else rpar=1; end
    //l'adresse du pointeur de z attention -1 pas sur
    if nz<>0 then z=zptr(bk)-1, else z=0;end
    //l'adresse du pointeur de x
    if nx<>0 then x=xptr(bk)-1, else x=0;end

    //**
    ftyp=funtyp(bk)
    if ftyp>2000 then ftyp=ftyp-2000,end
    if ftyp>1000 then ftyp=ftyp-1000,end

    //** check function type
    if ftyp < 0 then //** ifthenelse eselect blocks
        txt = [];
        return;
    else
        if (ftyp<>0 & ftyp<>1 & ftyp<>2 & ftyp<>3 & ftyp<>4) then
            disp("types other than 0,1,2,3 or 4 are not supported.")
            txt = [];
            return;
        end
    end

    select ftyp

    case 0 then
        //**** input/output addresses definition ****//
        if nin>1 then
            for k=1:nin
                uk=inplnk(inpptr(bk)-1+k);
                nuk=size(outtb(uk),"*");
                txt=[txt;
                "rdouttb["+string(k-1)+"]=(double *)"+rdnom+"_block_outtbptr["+string(uk-1)+"];"]
            end
            txt=[txt;
            "args[0]=&(rdouttb[0]);"]
        elseif nin==0
            uk=0;
            nuk=0;
            txt=[txt;
            "args[0]=(double *)"+rdnom+"_block_outtbptr[0];"]
        else
            uk=inplnk(inpptr(bk));
            nuk=size(outtb(uk),"*");
            txt=[txt;
            "args[0]=(double *)"+rdnom+"_block_outtbptr["+string(uk-1)+"];"]
        end

        if nout>1 then
            for k=1:nout
                yk=outlnk(outptr(bk)-1+k);
                nyk=size(outtb(yk),"*");
                txt=[txt;
                "rdouttb["+string(k+nin-1)+"]=(double *)"+rdnom+"_block_outtbptr["+string(yk-1)+"];"];
            end
            txt=[txt;
            "args[1]=&(rdouttb["+string(nin)+"]);"];
        elseif nout==0
            yk=0;
            nyk=0;
            txt=[txt;
            "args[1]=(double *)"+rdnom+"_block_outtbptr[0];"];
        else
            yk=outlnk(outptr(bk));
            nyk=size(outtb(yk),"*"),;
            txt=[txt;
            "args[1]=(double *)"+rdnom+"_block_outtbptr["+string(yk-1)+"];"];
        end
        //*******************************************//

        //*********** call seq definition ***********//
        txtc=["(&local_flag,&block_"+rdnom+"["+string(bk-1)+"].nevprt,&t,block_"+rdnom+"["+string(bk-1)+"].xd, \";
        "block_"+rdnom+"["+string(bk-1)+"].x,&block_"+rdnom+"["+string(bk-1)+"].nx, \";
        "block_"+rdnom+"["+string(bk-1)+"].z,&block_"+rdnom+"["+string(bk-1)+"].nz,block_"+rdnom+"["+string(bk-1)+"].evout, \";
        "&block_"+rdnom+"["+string(bk-1)+"].nevout,block_"+rdnom+"["+string(bk-1)+"].rpar,&block_"+rdnom+"["+string(bk-1)+"].nrpar, \";
        "block_"+rdnom+"["+string(bk-1)+"].ipar,&block_"+rdnom+"["+string(bk-1)+"].nipar, \";
        "(double *)args[0],&nrd_"+string(nuk)+",(double *)args[1],&nrd_"+string(nyk)+");"];
        if (funtyp(bk)>2000 & funtyp(bk)<3000)
            blank = get_blank(funs(bk)+"( ");
            txtc(1) = funs(bk)+txtc(1);
        elseif (funtyp(bk)<2000)
            txtc(1) = "C2F("+funs(bk)+")"+txtc(1);
            blank = get_blank("C2F("+funs(bk)+") ");
        end
        txtc(2:$) = blank + txtc(2:$);
        txt = [txt;txtc];
        //*******************************************//


        //**
    case 1 then
        //*********** call seq definition ***********//
        txtc=["(&local_flag,&block_"+rdnom+"["+string(bk-1)+"].nevprt,&t,block_"+rdnom+"["+string(bk-1)+"].xd, \";
        "block_"+rdnom+"["+string(bk-1)+"].x,&block_"+rdnom+"["+string(bk-1)+"].nx, \";
        "block_"+rdnom+"["+string(bk-1)+"].z,&block_"+rdnom+"["+string(bk-1)+"].nz,block_"+rdnom+"["+string(bk-1)+"].evout, \";
        "&block_"+rdnom+"["+string(bk-1)+"].nevout,block_"+rdnom+"["+string(bk-1)+"].rpar,&block_"+rdnom+"["+string(bk-1)+"].nrpar, \";
        "block_"+rdnom+"["+string(bk-1)+"].ipar,&block_"+rdnom+"["+string(bk-1)+"].nipar"];
        if (funtyp(bk)>2000 & funtyp(bk)<3000)
            blank = get_blank(funs(bk)+"( ");
            txtc(1) = funs(bk)+txtc(1);
        elseif (funtyp(bk)<2000)
            txtc(1) = "C2F("+funs(bk)+")"+txtc(1);
            blank = get_blank("C2F("+funs(bk)+") ");
        end
        if nin>=1 | nout>=1 then
            txtc($)=txtc($)+", \"
            txtc=[txtc;""]
            if nin>=1 then
                for k=1:nin
                    uk=inplnk(inpptr(bk)-1+k);
                    nuk=size(outtb(uk),"*");
                    txtc($)=txtc($)+"(double *)"+rdnom+"_block_outtbptr["+string(uk-1)+"],&nrd_"+string(nuk)+",";
                end
                txtc($)=part(txtc($),1:length(txtc($))-1); //remove last ,
            end
            if nout>=1 then
                if nin>=1 then
                    txtc($)=txtc($)+", \"
                    txtc=[txtc;""]
                end
                for k=1:nout
                    yk=outlnk(outptr(bk)-1+k);
                    nyk=size(outtb(yk),"*");
                    txtc($)=txtc($)+"(double *)"+rdnom+"_block_outtbptr["+string(yk-1)+"],&nrd_"+string(nyk)+",";
                end
                txtc($)=part(txtc($),1:length(txtc($))-1); //remove last ,
            end
        end

        if ztyp(bk) then
            txtc($)=txtc($)+", \"
            txtc=[txtc;
            "block_"+rdnom+"["+string(bk-1)+"].g,&block_"+rdnom+"["+string(bk-1)+"].ng);"]
        else
            txtc($)=txtc($)+");";
        end

        txtc(2:$) = blank + txtc(2:$);
        txt = [txt;txtc];
        //*******************************************//

        //**
    case 2 then

        //*********** call seq definition ***********//
        txtc=[funs(bk)+"(&local_flag,&block_"+rdnom+"["+string(bk-1)+"].nevprt,&t,block_"+rdnom+"["+string(bk-1)+"].xd, \";
        "block_"+rdnom+"["+string(bk-1)+"].x,&block_"+rdnom+"["+string(bk-1)+"].nx, \";
        "block_"+rdnom+"["+string(bk-1)+"].z,&block_"+rdnom+"["+string(bk-1)+"].nz,block_"+rdnom+"["+string(bk-1)+"].evout, \";
        "&block_"+rdnom+"["+string(bk-1)+"].nevout,block_"+rdnom+"["+string(bk-1)+"].rpar,&block_"+rdnom+"["+string(bk-1)+"].nrpar, \";
        "block_"+rdnom+"["+string(bk-1)+"].ipar,&block_"+rdnom+"["+string(bk-1)+"].nipar, \";
        "(double **)block_"+rdnom+"["+string(bk-1)+"].inptr,block_"+rdnom+"["+string(bk-1)+"].insz,&block_"+rdnom+"["+string(bk-1)+"].nin, \";
        "(double **)block_"+rdnom+"["+string(bk-1)+"].outptr,block_"+rdnom+"["+string(bk-1)+"].outsz, &block_"+rdnom+"["+string(bk-1)+"].nout"];
        if ~ztyp(bk) then
            txtc($)=txtc($)+");";
        else
            txtc($)=txtc($)+", \";
            txtc=[txtc;
            "block_"+rdnom+"["+string(bk-1)+"].g,&block_"+rdnom+"["+string(bk-1)+"].ng);"]
        end
        blank = get_blank(funs(bk)+"( ");
        txtc(2:$) = blank + txtc(2:$);
        txt = [txt;txtc];
        //*******************************************//

        //**
    case 4 then
        txt=[txt;
        funs(bk)+"(&block_"+rdnom+"["+string(bk-1)+"],local_flag);"];

    end

    txt =[txt;"if(local_flag < 0) return(5 - local_flag);"
    "end_"+funs(bk)+"=clock();"
    "total_"+funs(bk)+"=(double)(end_"+funs(bk)+"-start_"+funs(bk)+");"
    ]

endfunction
