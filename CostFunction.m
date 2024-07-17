function Cost = CostFunction(x,NumTask ,LDT ,Duration ,D ,NumMaterial ,UQ ,MatPro ,DDPC ,TFR ,OFR ,DPC,MatCost)

% %%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%
% %Method 1: dont use global paramet
% %%%%mohasebe mizane MRP(UQ) DQ BQ SQ
%part1:taine mizane mrp(m,t)
MRP = zeros(NumMaterial,Duration);
SQ = zeros(NumMaterial,Duration);
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
    
%part2:taine mizane material khridari shode(x ha) va mizane tahvil gerefte
%shode dar site DQ
DQ=zeros(NumMaterial,Duration);
BQ1=zeros(NumMaterial,Duration);
BQ2=zeros(NumMaterial,Duration);
for m = 1:NumMaterial
    %p=1 kharide naghdi
    %p=2 kharide ghesti
    for p =1:2
        for t = 1:Duration
            if p == 1
                BQ1(m,t) = x(NumTask + (((2*m)+p-3)*(Duration))+t)*1000;
            elseif p == 2
                BQ2(m,t) = x(NumTask + (((2*m)+p-3)*(Duration))+t)*1000;
            end
        end
    end
end


for m=1:NumMaterial
    for t= 1:Duration
        if t-MatPro{m}{4}>=0
            DQ(m,t)= DQ(m,t) + BQ1(m,t-MatPro{m}{4}+1) + BQ2(m,t-MatPro{m}{4}+1);
        end
    end
end

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
            if (UnitPriceP1Find == 0)&&(MatCost{m}{i}{1} <= BQ1(m,t)) && (MatCost{m}{i}{2} >= BQ1(m,t))
                UnitPriceP1 = MatCost{m}{i}{3}; 
                UnitPriceP1Find = 1;
            end
            if (UnitPriceP21Find == 0)&&(MatCost{m}{i}{1} <= BQ2(m,t)) && (MatCost{m}{i}{2} >= BQ2(m,t))
                UnitPriceP21 = MatCost{m}{i}{4}; 
                RateAtT0 = MatCost{m}{i}{5};
                UnitPriceP21Find = 1;
            end
            if (UnitPriceP22Find == 0)&&((t - MatPro{m}{5}) > 0) && (MatCost{m}{i}{1} <= BQ2(m,t- MatPro{m}{4})) && (MatCost{m}{i}{2} >= BQ2(m,t- MatPro{m}{5}))
                UnitPriceP22 = MatCost{m}{i}{4}; 
                RateAtDelta = MatCost{m}{i}{6};
                UnitPriceP22Find = 1;
            end
            if (UnitPriceP22Find == 1)&& (UnitPriceP21Find == 1)&&(UnitPriceP1Find == 1)
                break
            end
        end
        
        if (t - MatPro{m}{5}) > 0
            OC(m,t)=(BQ2(m,t) * UnitPriceP21 * RateAtT0 * ((1+MatPro{m}{6})^(Duration-t))) + (BQ2(m,t- MatPro{m}{5}) *  UnitPriceP22 * RateAtDelta * ((1+MatPro{m}{6})^(Duration-t+MatPro{m}{5}))) + (BQ1(m,t)  * UnitPriceP1 * ((1+MatPro{m}{6})^(Duration-t)));
        else
            OC(m,t)=(BQ2(m,t) * UnitPriceP21 * RateAtT0 * ((1+MatPro{m}{6})^(Duration-t))) + (BQ1(m,t) * UnitPriceP1 * ((1+MatPro{m}{6})^(Duration-t))); 
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
%part4:hazine takhir
if (x(NumTask)+D(NumTask)) >(days(DDPC-LDT)+1)
    temp_dif_T = string(x(NumTask)+D(NumTask) - (days(DDPC-LDT)+1));
    temp=textscan(temp_dif_T,'%f');
    Diff = double(temp{1});
    DFP = Diff * DPC;
else
    DFP=0;
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
total_oc=0;
total_dc=0;
total_sc=0;
cost = 0;
for t = 1:Duration
    Temp_total_cost_t =0;
    for m = 1:NumMaterial
        Temp_total_cost_t = Temp_total_cost_t + OC(m,t)+ DC(m,t) + SC(m,t) ;
%         total_oc=total_oc+OC(m,t);
%         total_dc=total_dc+DC(m,t);
%         total_sc=total_sc+SC(m,t);

    end
    FPI = (1+OFR)^(Duration-t);
    cost = cost + ((Temp_total_cost_t) * FPI);
end
CostPart1 =(cost + DFP);


% % % Method 2 function: use cash flow and FI
% 
% FI=[];
% for t =1:Duration
%     Temp_total_cost_t = 0;
%     for m = 1:NumMaterial
%         Temp_total_cost_t = Temp_total_cost_t + OC(m,t) + DC(m,t) + SC(m,t) ;
%     end
%     if t == 1
%         FI(t) = B(t) - Temp_total_cost_t;
%     elseif t == Duration
%         FI(t) = (FI(t-1)*(1+IR)) + B(t) - Temp_total_cost_t - DFP;
%     else
%         FI(t) = (FI(t-1)*(1+IR)) + B(t) - Temp_total_cost_t;
%     end
% end
% 
% cost = 0;
% for t = 1:Duration
%     FPI = (1+OFR)^(Duration-t);
%     cost = cost + (FI(t) * FPI);
% end
% CostPart1 = -(cost);

%%%%%%%%%%%%%%%%%%%%%%%
%mohasebe navasane hajme mavad mojod dar anbar(part1 tabe hadaf)

% VolumeFlac=0;
% if WSPACE ~=0
%     for m = 1:NumMaterial
%         DifVolMat=0;
%         for t = 2:Duration
%             DifVolMat = DifVolMat +(SQ(m,t)-SQ(m,t-1))^2;
%         end
%         VolumeFlac = VolumeFlac + MatPro{m}{14}*DifVolMat;
%     end
%     CostPart2 = WSPACE*(AreaFlac);
% else 
%     CostPart2=0;
% end
% 
% Cost=CostPart1+CostPart2;
Cost=CostPart1;

end