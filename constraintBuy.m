function z = constraintBuy(x,DFP,MRP,OptScenarioNum ,Duration ,NumMaterial  ,MatPro ,ProfSurArea ,StockLength ,StockWidth ,StockHeight ,TFR ,MatCost ,B,MaxSQ)

c=[];

%%%%%%%%%%%%%%%%%%%%%%%%%%
%part2:taine mizane material khridari shode(x ha) va mizane tahvil gerefte
%shode dar site DQ
DQ=zeros(NumMaterial,Duration);
BQ1=zeros(NumMaterial,Duration);
BQ2=zeros(NumMaterial,Duration);
for m = 1:NumMaterial
    for t = 1:Duration
        BQ1(m,t) = x((((2*m)+1-3)*(Duration))+t)*1000*(x((((2*m)+2-3)*(Duration))+t));
        BQ2(m,t) = x((((2*m)+1-3)*(Duration))+t)*1000*(1-x((((2*m)+2-3)*(Duration))+t));
    end   
end
Okeymeqgdar=[];
for m = 1:NumMaterial
        c=[c;sum(MRP(m,:))-sum(BQ1(m,:))-sum(BQ2(m,:))-50];
        Okeymeqgdar=[Okeymeqgdar;sum(MRP(m,:))-sum(BQ1(m,:))-sum(BQ2(m,:))-50];
end






% % % barasiye khardie bara bar az meghdar mrp
% for m = 1:NumMaterial
%     SumQM = 0;
%     for t = 1:Duration
%         for p =1:2
%             if SumQM > (ceil((TQM(m) * MatPro{m}{9}))+100)
%                 c = [c;x(NumTask + (((2*m)+p-3)*(Duration))+t)];
%             else
%                 c = [c;-x(NumTask + (((2*m)+p-3)*(Duration))+t)];
%             end
%             SumQM = SumQM + x(NumTask + (((2*m)+p-3)*(Duration))+t)*1000;
%             
%         end
%     end
% 
% end

%%barasiye adme khardi dar roz akhar be elat fasle zamani tahvil matreial


for m=1:NumMaterial
    for t= 1:Duration
        if t-MatPro{m}{4}>0
            DQ(m,t)= DQ(m,t) + BQ1(m,t-MatPro{m}{4}) + BQ2(m,t-MatPro{m}{4});
        end
    end
end
            

                                

%part3:mohasebe mizane mojodie anbar bar hasbe hajm (vol)
for m = 1:NumMaterial
    for t = 1:Duration
         if t==1
             SQ(m,t) = MatPro{m}{3} + (DQ(m,t));
         else
             SQ(m,t) = SQ(m,t-1) + (DQ(m,t)) - (MRP(m,t-1));
         end     
    end
end



%%%mahdodiat shoro yek task
for t = 1:Duration
    for m = 1:NumMaterial
        c=[c;MRP(m,t)-SQ(m,t)-10];
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%mahdodiat tamine mali
%part1:hazine kharide 
OC=zeros(NumMaterial,Duration);
for t =1:Duration
    for m = 1:NumMaterial
        UnitPriceP1 = 0;
        UnitPriceP1Find = 0;
        UnitPriceP21 = 0;
        UnitPriceP21Find = 0;
        UnitPriceP22 = 0;
        UnitPriceP22Find = 0;
        RateAtT0 = 0;
        RateAtDelta = 0;
        for i = 1:numel(MatCost{m})
            if (UnitPriceP1Find == 0)&&(MatCost{m}{i}{1} <= BQ1(m,t)) && (MatCost{m}{i}{2} >= BQ1(m,t))
                UnitPriceP1 = MatCost{m}{i}{3}; 
                UnitPriceP1Find = 1;
            end
            if (UnitPriceP21Find == 0)&&(MatCost{m}{i}{1} <= BQ2(m,t)) && (MatCost{m}{i}{2} >= BQ2(m,t))
                UnitPriceP21 = MatCost{m}{i}{4}; 
                RateAtT0 = MatCost{m}{i}{5};
                UnitPriceP21Find = 1;
            end
            if (UnitPriceP22Find == 0)&&((t - MatPro{m}{5}) > 0) && (MatCost{m}{i}{1} <= BQ2(m,t- MatPro{m}{5})) && (MatCost{m}{i}{2} >= BQ2(m,t- MatPro{m}{5}))
                UnitPriceP22 = MatCost{m}{i}{4};
                RateAtDelta = MatCost{m}{i}{6};
                UnitPriceP22Find = 1;
            end
            if (UnitPriceP22Find == 1)&& (UnitPriceP21Find == 1)&&(UnitPriceP1Find == 1)
                break
            end
        end

        if (t - MatPro{m}{5}) > 0
            OC(m,t)=(BQ2(m,t) * UnitPriceP21 * RateAtT0 * ((1+MatPro{m}{6})^(t-1))) + (BQ2(m,t- MatPro{m}{5}) *  UnitPriceP22 * RateAtDelta * ((1+MatPro{m}{6})^(t-MatPro{m}{5}-1))) + (BQ1(m,t)  * UnitPriceP1 * ((1+MatPro{m}{6})^(t-1)));
        else
            OC(m,t)=(BQ2(m,t) * UnitPriceP21 * RateAtT0 * ((1+MatPro{m}{6})^(t-1))) + (BQ1(m,t) * UnitPriceP1 * ((1+MatPro{m}{6})^(t-1)));
        end
        
    end
end
%part2:hazine haml
DC=zeros(NumMaterial,Duration);
for t =1:Duration
    for m = 1:NumMaterial
        DeliveryCost = 0;
        if DQ(m,t)~=0
            for i = 1:numel( MatCost{m})
                if (MatCost{m}{i}{1} <= DQ(m,t)) && (MatCost{m}{i}{2} >= DQ(m,t))
                    DeliveryCost = MatCost{m}{i}{7}; 
                    DC(m,t)= DeliveryCost * ((1+TFR)^(t));
                    break
                end
            end
        end
    end
end
%part3:hazine negahdari
SC=zeros(NumMaterial,Duration);
for t =1:Duration
    for m = 1:NumMaterial
        if SQ(m,t)>0
            SC(m,t) = SQ(m,t) * MatPro{m}{7}/MatPro{m}{9};
        end
    end
end

%part5:mojidi mali
FI=zeros(1,Duration);
for t =1:Duration
    Temp_total_cost_t = 0;
    for m = 1:NumMaterial
        Temp_total_cost_t = Temp_total_cost_t + OC(m,t) + DC(m,t) + SC(m,t) ;
    end
    if t == 1
        FI(t) = B(t) - Temp_total_cost_t;
    elseif t == Duration
        FI(t) = (FI(t-1)*(1)) + B(t) - Temp_total_cost_t - DFP;
    else
        FI(t) = (FI(t-1)*(1)) + B(t) - Temp_total_cost_t;
    end
end
%part6:check kardne manif nashodane FI
for t = 1:Duration
    c=[c;-FI(t)];
end

c;
for m=1:NumMaterial
    c=[c;  max(SQ(m,:))-MaxSQ(m)-100];
end
% %%%%%%%%%%%%%%%%%%%%%%%
% 
% %%%%%%%%%%%%%%%%%%%%%
% %%%%mahdodiat hajme anbar
% 
% 
TotalAreaUsedInStock=0;
AreaNeed=zeros(NumMaterial,3);
for m = 1:NumMaterial
    TotalLen=0;
    SpaceNeed=0;
    MaxNumRow=0;
    h_space=0;
    AreaNeedforMat=0;
    MatUnitNum=0;
    if max(SQ(m,:))==0
        AreaNeedforMat=0;
        l_space=0;
        w_space =0;
    elseif MatPro{m}{8} == "NoProfile"
        %%%baraye ajor o siman o kashi!
        %%%%bayad kar beshe
        SpaceNeed=max(SQ(m,:))/MatPro{m}{9};
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
        TotalLen=(max(SQ(m,:))/MatPro{m}{9})/ProfSurArea(m);
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
        SpaceNeed=max(SQ(m,:))/MatPro{m}{9};
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