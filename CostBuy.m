function z = CostBuy(x,DFP,MRP,Duration,NumMaterial,MatPro,TFR,OFR,MatCost,OptScenarioNum ,StockLength ,StockWidth ,StockHeight,B,ProfSurArea,MaxSQ)
% % % Check constraint
SumCposB = constraintBuy(x,DFP,MRP,OptScenarioNum ,Duration ,NumMaterial  ,MatPro ,ProfSurArea ,StockLength ,StockWidth ,StockHeight ,TFR ,MatCost ,B,MaxSQ);
if SumCposB<0
    z=SumCposB*10000000000000;
else
    %part2:taine mizane material khridari shode(x ha) va mizane tahvil gerefte
    %shode dar site DQ
    DQ=zeros(NumMaterial,Duration);
    BQ1=zeros(NumMaterial,Duration);
    BQ2=zeros(NumMaterial,Duration);
    for m = 1:NumMaterial
        for t = 1:Duration
            BQ1(m,t) = round(x((((2*m)+1-3)*(Duration))+t)*1000*(x((((2*m)+2-3)*(Duration))+t)));
            BQ2(m,t) = round(x((((2*m)+1-3)*(Duration))+t)*1000*(1-x((((2*m)+2-3)*(Duration))+t)));
        end   
    end
    for m=1:NumMaterial
           for t= 1:Duration
                if t-MatPro{m}{4}>0
                    DQ(m,t)= DQ(m,t) + BQ1(m,t-MatPro{m}{4}) + BQ2(m,t-MatPro{m}{4});
                end
            end
        
    end
% %%%Validation
%     for m=1:NumMaterial
%         if (m==1) || (m==5) || (m==6) || (m==8)
%             for t= 1:Duration
%                 if t-MatPro{m}{4}>0
%                     DQ(m,t)= floor(DQ(m,t) + BQ1(m,t-MatPro{m}{4}) + BQ2(m,t-MatPro{m}{4}));
%                 end
%             end
%         else
%             for t= 1:Duration
%                 if t-MatPro{m}{4}>0
%                     DQ(m,t)= DQ(m,t) + BQ1(m,t-MatPro{m}{4}) + BQ2(m,t-MatPro{m}{4});
%                 end
%             end
%         end
%     end

    %part3:mohasebe mizane mojodie anbar
    for m = 1:NumMaterial
        for t = 1:Duration
             if t==1
                 SQ(m,t) = MatPro{m}{3} + (DQ(m,t));
             else
                 SQ(m,t) = SQ(m,t-1) + (DQ(m,t)) - (MRP(m,t-1));
             end     
        end
    end
    %%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
                if (UnitPriceP1Find == 0)&&(MatCost{m}{i}{1} <= BQ1(m,t)) && (MatCost{m}{i}{2} >= BQ1(m,t))&& (BQ1(m,t)>0)
                    UnitPriceP1 = MatCost{m}{i}{3}; 
                    UnitPriceP1Find = 1;
                end
                if (UnitPriceP21Find == 0)&&(MatCost{m}{i}{1} <= BQ2(m,t)) && (MatCost{m}{i}{2} >= BQ2(m,t))&&(BQ2(m,t)>0)
                    UnitPriceP21 = MatCost{m}{i}{4}; 
                    RateAtT0 = MatCost{m}{i}{5};
                    UnitPriceP21Find = 1;
                end
           
                if (UnitPriceP22Find == 0)&&((t - MatPro{m}{5}) > 0) && (MatCost{m}{i}{1} <= BQ2(m,t- MatPro{m}{5})) && (MatCost{m}{i}{2} >= BQ2(m,t- MatPro{m}{5}))&&(BQ2(m,t- MatPro{m}{5})>0)
                    UnitPriceP22 = MatCost{m}{i}{4};
                    RateAtDelta = MatCost{m}{i}{6};
                    UnitPriceP22Find = 1;
                end
                
            end
            if (t - MatPro{m}{5}) > 0
                OC(m,t)=(BQ2(m,t) * UnitPriceP21 * RateAtT0 * ((1+MatPro{m}{6})^(t-1))) + (BQ2(m,t- MatPro{m}{5}) *  UnitPriceP22 * RateAtDelta * ((1+MatPro{m}{6})^(t-MatPro{m}{5}-1))) + (BQ1(m,t)  * UnitPriceP1 * ((1+MatPro{m}{6})^(t-1)));
            else
                OC(m,t)=(BQ2(m,t) * UnitPriceP21 * RateAtT0 * ((1+MatPro{m}{6})^(t-1))) + (BQ1(m,t) * UnitPriceP1 * ((1+MatPro{m}{6})^(t-1))); 
            end

        end
    end
    % part2:hazine haml
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
    %part5:hazine tamin malie
    %part5-1: mohasebe average cost kharid material (AOCm)

    %Method2: use global paramet
    % AOC = [];
    % for m = 1:NumMaterial
    %     Sum_OC = 0;
    %     Sum_DQ = 0;
    %     for t = 1:Duration
    %         Sum_OC = Sum_OC + OC(m,t);
    %         Sum_DQ = Sum_DQ + DQ(m,t);
    %     end
    %     AOC(m) = Sum_OC / Sum_DQ;
    % end
    % %part5-2: mhazine tamin malie(cc)
    % CC=zeros(1,Duration);
    % for t = 1:Duration
    %     for m = 1:NumMaterial
    %         CC(t)=CC(t) + AOC(m) * IR;
    %     end
    % end

    %%%%%%%%%%%%%%%%%%%

    % % Method 1 function: use Capital Cost
    % % mohasebe arzeshe hazine ha dar zaman MaxDeliveryDateofProject(part1 tabe
    % % hadaf)
    temTotalOC=0;
    tempTotalDC=0;
    tempTotalSC=0;
    cost = 0;
    for t = 1:Duration
        Temp_total_cost_t =0;
        for m = 1:NumMaterial
            Temp_total_cost_t = Temp_total_cost_t + OC(m,t)+ DC(m,t) + SC(m,t) ;
            temTotalOC=temTotalOC+OC(m,t);
            tempTotalDC=tempTotalDC+DC(m,t);
            tempTotalSC=tempTotalSC+SC(m,t);
        end
        FPI = (1+OFR)^(Duration-t);
        cost = cost + ((Temp_total_cost_t) * FPI);
    end
    CostPart1 =cost;
    %%%
    z=CostPart1;
    if CostPart1<17000000000
        a=1;
    end

    
end


end