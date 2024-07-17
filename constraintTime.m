function z = constraintTime(x,OptScenarioNum ,WESTask ,WEFTask ,WLSTask ,WLFTask ,Predecessors ,NumTask ,Duration ,D ,NumMaterial ,UQ ,MatPro ,ProfSurArea ,StockLength ,StockWidth ,StockHeight)

c=[];

for n=1:NumTask
    if isnan(WESTask(n))==0
        c = [c;WESTask(n)-x(n)];
    end

    if isnan(WEFTask(n))==0
        c = [c;WEFTask(n)-x(n)-D(n)-1];
    end

    if isnan(WLSTask(n))==0
        c = [c;x(n)-WLSTask(n)];
    end

    if isnan(WLFTask(n))==0
        c = [c;x(n)-D(n)-1-WLFTask(n)];
    end
%     disp(Predecessors{n}{1})
    if Predecessors{n}{1}=="Nothing"
        %x(n)>= ESPC;
        %x(n)+D(n) <= MDDP;
        c = [c;-x(n);x(n)+D(n)-1-Duration];
        
    else
        for p=1:numel(Predecessors{n})
            temp=textscan(Predecessors{n}{p},'%s','Delimiter',',');
            taskID=str2double((temp{1}{1}));
            rel=temp{1}{2};
            lag=str2double(temp{1}{3});
            if rel=="FS"
                %x(n) >= x(taskID) + D(taskID) + lag;
                %x(n)+D(n) <= MDDP;
                %x(n)>= ESPC;
                c=[c;x(taskID) + D(taskID) - 1 + lag - x(n);-x(n);x(n)+D(n)-1-Duration];
            elseif rel=="SS"
                %x(n) >= x(taskID) + lag;
                %x(n)+D(n) <= MDDP;
                %x(n)>= ESPC;
                c=[c;x(taskID) + lag - x(n);-x(n);x(n)+D(n)-1-Duration];
            elseif rel=="FF"
                %x(n) >= x(taskID) + D(taskID) + lag - D(n);
                %x(n)+D(n) <= MDDP;
                %x(n)>= ESPC;
                c=[c;x(taskID) + D(taskID) + lag - x(n) - D(n);-x(n);x(n)+D(n)-1-Duration];
            elseif rel=="SF"
                %x(n) >= x(taskID) + lag - D(n);
                %x(n)+D(n) <= MDDP;
                %x(n)>= ESPC;
                c=[c;x(taskID) + lag - x(n) - D(n)+1;-x(n);x(n)+D(n)-1-Duration];
            end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%mohasebe mizane MRP(UQ) DQ BQ SQ
%part1:taine mizane mrp(m,t)
%c;
MRP = zeros(NumMaterial,Duration);
Q=[];
for t = 1:Duration
% dar har roz yek matrix q ba tedad satre barabar ba material va sotone
% barabar ba tedad failat ha ijad mikonim ta mizane morede niaz material
% moshakhas shavad
    Q{t}=zeros(NumMaterial,NumTask);
    for n = 1:NumTask
        if (x(n)<=t) && (t<=x(n)+D(n)-1)
            for m = 1:NumMaterial
                Q{t}(m,n) = Q{t}(m,n) + UQ(m,n)*MatPro{m}{9};
            end
        end 
    end
    for m = 1:NumMaterial
       for n = 1:NumTask
           MRP(m,t) = MRP(m,t) + Q{t}(m,n);
       end
    end
end



%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%
%%%%mahdodiat hajme anbar


TotalAreaUsedInStock=0;
AreaNeed=zeros(NumMaterial,3);
for m = 1:NumMaterial
    TotalLen=0;
    SpaceNeed=0;
    MaxNumRow=0;
    h_space=0;
    AreaNeedforMat=0;
    MatUnitNum=0;
    if max(MRP(m,:))==0
        AreaNeedforMat=0;
        l_space=0;
        w_space =0;
    elseif MatPro{m}{8} == "NoProfile"
        %%%baraye ajor o siman o kashi!
        %%%%bayad kar beshe
        SpaceNeed=max(MRP(m,:))/MatPro{m}{9};
        MatUnitNum = ceil(SpaceNeed/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10}));
        MaxNumRow=floor(StockHeight{OptScenarioNum}{m}/MatPro{m}{11});
        if MatUnitNum*MatPro{m}{11}>StockHeight{OptScenarioNum}{m}
            h_space=MaxNumRow*MatPro{m}{11};
        else
            h_space=MatUnitNum*MatPro{m}{11};
        end
        l_space = MatPro{m}{12};
        WidthNeedforSpace =MatPro{m}{10}*ceil(SpaceNeed/(h_space*l_space)/MatPro{m}{10});
        if WidthNeedforSpace>StockWidth{OptScenarioNum}{m}
            w_space = MatPro{m}{10}*floor(StockWidth{OptScenarioNum}{m}/MatPro{m}{10});
            UnitArrangeDone = (h_space * w_space * l_space)/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
            UnitNeedtArrange = MatUnitNum - UnitArrangeDone ;
            SpaceNeedforRest = UnitNeedtArrange*(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
            if (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m})
                NumLenAvaInWidth =  floor(StockWidth{OptScenarioNum}{m}/MatPro{m}{12});
            else
                NumLenAvaInWidth =1;
            end
            if UnitNeedtArrange*MatPro{m}{11}/NumLenAvaInWidth>StockHeight{OptScenarioNum}{m}
                h_space_rest=MaxNumRow*MatPro{m}{11}; 
            else
                h_space_rest=MatUnitNum*MatPro{m}{11}/NumLenAvaInWidth;
            end
            AreaNeedforRest = SpaceNeedforRest/h_space_rest;
            LengthNeedforRest = AreaNeedforRest/w_space;

            if (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest<=MatPro{m}{12})
                ExtraLengthNeed =MatPro{m}{10}*ceil(SpaceNeedforRest/(h_space_rest*w_space)/MatPro{m}{10});
                l_space = l_space + ExtraLengthNeed;

            elseif (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest>MatPro{m}{12})
                Extralen_1 =  MatPro{m}{12} * floor(LengthNeedforRest/MatPro{m}{12});
                UnitDoneinExtra1 = (h_space * w_space * Extralen_1)/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                RestUnit = UnitNeedtArrange - UnitDoneinExtra1;
                SpaceNeedRestUnit2 = RestUnit*(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                if UnitNeedtArrange*MatPro{m}{11}/NumLenAvaInWidth>StockHeight{OptScenarioNum}{m}
                    h_space_rest2=MaxNumRow*MatPro{m}{11}; 
                else
                    h_space_rest2=MatUnitNum*MatPro{m}{11}/NumLenAvaInWidth;
                end

                Extralen_2 = MatPro{m}{10}*ceil(SpaceNeedRestUnit2/(h_space_rest2*w_space)/MatPro{m}{10});
                l_space = l_space +  Extralen_1 + Extralen_2  ;
            elseif (MatPro{m}{12}> StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest>MatPro{m}{12})
                ExtraLengthNeed = MatPro{m}{12}* ceil(LengthNeedforRest/MatPro{m}{12});
                l_space = l_space + ExtraLengthNeed;   
            end

        else
            temp_w_space = MatPro{m}{10}*ceil(SpaceNeed/(h_space*l_space)/MatPro{m}{10});
            if temp_w_space + 2 > StockWidth{OptScenarioNum}{m}
                w_space = StockWidth{OptScenarioNum}{m};
            else
                w_space = temp_w_space;
            end
            l_space = MatPro{m}{12};
        end
        AreaNeedforMat=l_space * w_space;


    elseif MatPro{m}{8}(1:2) ~= "PL"
        TotalLen=(max(MRP(m,:))/MatPro{m}{9})/ProfSurArea(m);
        MatUnitNum = ceil(TotalLen/MatPro{m}{12});
        SpaceNeed= MatUnitNum*MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10};
        MaxNumRow=floor(StockHeight{OptScenarioNum}{m}/MatPro{m}{11});
        if MatUnitNum*MatPro{m}{11}>StockHeight{OptScenarioNum}{m}
            h_space=MaxNumRow*MatPro{m}{11};
        else
            h_space=MatUnitNum*MatPro{m}{11};
        end
        l_space = MatPro{m}{12};
        WidthNeedforSpace =MatPro{m}{10}*ceil(SpaceNeed/(h_space*l_space)/MatPro{m}{10});
        if WidthNeedforSpace>StockWidth{OptScenarioNum}{m}
            w_space = MatPro{m}{10}*floor(StockWidth{OptScenarioNum}{m}/MatPro{m}{10});
            UnitArrangeDone = (h_space * w_space * l_space)/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
            UnitNeedtArrange = MatUnitNum - UnitArrangeDone ;
            SpaceNeedforRest = UnitNeedtArrange*(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
            if (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m})
                NumLenAvaInWidth =  floor(StockWidth{OptScenarioNum}{m}/MatPro{m}{12});
            else
                NumLenAvaInWidth =1;
            end
            if UnitNeedtArrange*MatPro{m}{11}/NumLenAvaInWidth>StockHeight{OptScenarioNum}{m}
                h_space_rest=MaxNumRow*MatPro{m}{11}; 
            else
                h_space_rest=MatUnitNum*MatPro{m}{11}/NumLenAvaInWidth;
            end
            AreaNeedforRest = SpaceNeedforRest/h_space_rest;
            LengthNeedforRest = AreaNeedforRest/w_space;

            if (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest<=MatPro{m}{12})
                ExtraLengthNeed =MatPro{m}{10}*ceil(SpaceNeedforRest/(h_space_rest*w_space)/MatPro{m}{10});
                l_space = l_space + ExtraLengthNeed ;

            elseif (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest>MatPro{m}{12})
                Extralen_1 =  MatPro{m}{12} * floor(LengthNeedforRest/MatPro{m}{12});
                UnitDoneinExtra1 = (h_space * w_space * Extralen_1)/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                RestUnit = UnitNeedtArrange - UnitDoneinExtra1;
                SpaceNeedRestUnit2 = RestUnit*(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                if UnitNeedtArrange*MatPro{m}{11}/NumLenAvaInWidth>StockHeight{OptScenarioNum}{m}
                    h_space_rest2=MaxNumRow*MatPro{m}{11}; 
                else
                    h_space_rest2=MatUnitNum*MatPro{m}{11}/NumLenAvaInWidth;
                end

                Extralen_2 = MatPro{m}{10}*ceil(SpaceNeedRestUnit2/(h_space_rest2*w_space)/MatPro{m}{10});
                l_space = l_space +  Extralen_1 + Extralen_2 ;
            elseif (MatPro{m}{12}> StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest>MatPro{m}{12})
                ExtraLengthNeed = MatPro{m}{12}* ceil(LengthNeedforRest/MatPro{m}{12});
                l_space = l_space + ExtraLengthNeed ;   
            end

        else
            temp_w_space = MatPro{m}{10}*ceil(SpaceNeed/(h_space*l_space)/MatPro{m}{10});
            if temp_w_space + 2 > StockWidth{OptScenarioNum}{m}
                w_space = StockWidth{OptScenarioNum}{m};
            else
                w_space = temp_w_space;
            end
            l_space = MatPro{m}{12};
        end
        AreaNeedforMat=l_space * w_space;


    elseif MatPro{m}{8}(1:2) == "PL"
        SpaceNeed=max(MRP(m,:))/MatPro{m}{9};
        MatUnitNum = ceil(SpaceNeed/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10}));
        MaxNumRow=floor(StockHeight{OptScenarioNum}{m}/MatPro{m}{11});
        if MatUnitNum*MatPro{m}{11}>StockHeight{OptScenarioNum}{m}
            h_space=MaxNumRow*MatPro{m}{11};
        else
            h_space=MatUnitNum*MatPro{m}{11};
        end
        l_space = MatPro{m}{12};
        WidthNeedforSpace =MatPro{m}{10}*ceil(SpaceNeed/(h_space*l_space * MatPro{m}{10}));
        if WidthNeedforSpace>StockWidth{OptScenarioNum}{m}
            w_space = MatPro{m}{10}*floor(StockWidth{OptScenarioNum}{m}/MatPro{m}{10});
            UnitArrangeDone = (h_space * w_space * l_space)/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
            UnitNeedtArrange = MatUnitNum - UnitArrangeDone ;
            SpaceNeedforRest = UnitNeedtArrange*(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
            if (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m})
                NumLenAvaInWidth =  floor(StockWidth{OptScenarioNum}{m}/MatPro{m}{12});
            else
                NumLenAvaInWidth =1;
            end
            if UnitNeedtArrange*MatPro{m}{11}/NumLenAvaInWidth>StockHeight{OptScenarioNum}{m}
                h_space_rest=MaxNumRow*MatPro{m}{11}; 
            else
                h_space_rest=MatUnitNum*MatPro{m}{11}/NumLenAvaInWidth;
            end
            AreaNeedforRest = SpaceNeedforRest/h_space_rest;
            LengthNeedforRest = AreaNeedforRest/w_space;

            if (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest<=MatPro{m}{12})
                ExtraLengthNeed =MatPro{m}{10}*ceil(SpaceNeedforRest/(h_space_rest*w_space)/MatPro{m}{10});
                l_space = l_space + ExtraLengthNeed;

            elseif (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest>MatPro{m}{12})
                Extralen_1 =  MatPro{m}{12} * floor(LengthNeedforRest/MatPro{m}{12});
                UnitDoneinExtra1 = (h_space * w_space * Extralen_1)/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                RestUnit = UnitNeedtArrange - UnitDoneinExtra1;
                SpaceNeedRestUnit2 = RestUnit*(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                if UnitNeedtArrange*MatPro{m}{11}/NumLenAvaInWidth>StockHeight{OptScenarioNum}{m}
                    h_space_rest2=MaxNumRow*MatPro{m}{11}; 
                else
                    h_space_rest2=MatUnitNum*MatPro{m}{11}/NumLenAvaInWidth;
                end

                Extralen_2 = MatPro{m}{10}*ceil(SpaceNeedRestUnit2/(h_space_rest2*w_space)/MatPro{m}{10});
                l_space = l_space +  Extralen_1 + Extralen_2;
            elseif (MatPro{m}{12}> StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest>MatPro{m}{12})
                ExtraLengthNeed = MatPro{m}{12}* ceil(LengthNeedforRest/MatPro{m}{12});
                l_space = l_space + ExtraLengthNeed;   
            end

        else
            temp_w_space = MatPro{m}{10}*ceil(SpaceNeed/(h_space*l_space)/MatPro{m}{10});
            if temp_w_space + 2 > StockWidth{OptScenarioNum}{m}
                w_space = StockWidth{OptScenarioNum}{m};
            else
                w_space = temp_w_space;
            end
            l_space = MatPro{m}{12};

        end
        AreaNeedforMat=l_space * w_space;
    end
    AreaNeed(m,1) = l_space;
    AreaNeed(m,2) = w_space;
    AreaNeed(m,3) = AreaNeedforMat;
    c=[c;AreaNeed(m,1)-StockLength{OptScenarioNum}{m}; AreaNeed(m,2)-StockWidth{OptScenarioNum}{m}];

end

sumCpos=0;
for ci=1:numel(c)
   if c(ci)>0 
       sumCpos= sumCpos+c(ci);
   end
end
z=sumCpos;
end