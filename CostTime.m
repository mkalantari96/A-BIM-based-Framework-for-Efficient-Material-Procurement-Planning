
function z = CostTime(x,MaxQMat,NumTask,LDT,Duration,D,NumMaterial,UQ,MatPro,DDPC,TFR,OFR,DPC,MatCost,OptScenarioNum, WESTask ,WEFTask ,WLSTask ,WLFTask ,TQM ,Predecessors,StockLength ,StockWidth ,StockHeight,B,ProfSurArea)
    z=[];
    
    digits(4);
    % % % Check constraint
    SumCposTime = constraintTime(x,OptScenarioNum ,WESTask ,WEFTask ,WLSTask ,WLFTask ,Predecessors ,NumTask ,Duration ,D ,NumMaterial ,UQ ,MatPro ,ProfSurArea ,StockLength ,StockWidth ,StockHeight);
    %part4:hazine takhir
    if SumCposTime>0
        z{1}=99999999999999999999999999999999999999999999999999999999999999999;
        z{2}=zeros(NumMaterial,Duration);
    else

        if (x(NumTask)+D(NumTask)) >(days(DDPC-LDT)+1)
            temp_dif_T = string(x(NumTask)+D(NumTask) - (days(DDPC-LDT)+1));
            temp=textscan(temp_dif_T,'%f');
            Diff = double(temp{1});
            DFP = Diff * DPC;
        else
            DFP=0;
        end

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
        
        %max capacity Storage
        MaxSQ=zeros(NumMaterial,1);
        for m=1:NumMaterial
            Ha=floor(StockHeight{OptScenarioNum}{m}/MatPro{m}{11});
            %lengthUnit dar rastaye lenghtStorage
            Wa=floor(StockWidth{OptScenarioNum}{m}/MatPro{m}{10});
            Lt=StockLength{OptScenarioNum}{m}/MatPro{m}{12};
            La=floor(Lt);
            Let=Lt-La;
            FirstUnitCap=Wa*La*Ha;
            if Let==0
                SecondUnitCap=0;
            else
                We=floor(Let/MatPro{m}{10});
                Le=floor(StockWidth{OptScenarioNum}{m}/MatPro{m}{12});
                SecondUnitCap=We*Le*Ha;
            end
            TotalUnitCap=FirstUnitCap+SecondUnitCap;

            if MatPro{m}{8} == "NoProfile"
                MaxSQ(m)=TotalUnitCap*MatPro{m}{9};
            elseif MatPro{m}{8}(1:2) ~= "PL"
                MaxSQ(m)=TotalUnitCap*(MatPro{m}{9}*ProfSurArea(m)*MatPro{m}{12});
            elseif MatPro{m}{8}(1:2) == "PL"
                MaxSQ(m)=TotalUnitCap*(MatPro{m}{9}*MatPro{m}{10}*MatPro{m}{11}*MatPro{m}{12});
            end
        end
        
        lastIndexX=(2*NumMaterial +2 - 2)*Duration;
        LB=[];
        UB=[];
        for m = 1:NumMaterial
            for p = 1:2
                for t = 1:Duration
                    if p==1
                        
                        if (t>1) && (t+MatPro{m}{4}<208)
                            UB = [UB min(MaxSQ(m),min(MaxQMat{m},(TQM(m)*MatPro{m}{9}-sum(MRP(m,1:t+MatPro{m}{4}-1)))))/1000];
                            LB = [LB MRP(m,t+MatPro{m}{4})/1000]; 
                        elseif t==1
                            UB = [UB min(MaxSQ(m),min(MaxQMat{m},TQM(m)*MatPro{m}{9}))/1000];
                            LB = [LB MRP(m,t+MatPro{m}{4})/1000]; 
                        else
                            UB = [UB 0];
                            LB = [LB 0]; 
                        end

                    else
                        LB=[LB 0];
                        UB = [UB 1];
                    end
                end
            end
        end

        %% Problem Definition


        nvars=lastIndexX;
        nVar = lastIndexX;            % Number of Decision Variables

        VarSize = [1 nVar];   % Size of Decision Variables Matrix

        VarMin = LB;         % Lower Bound of Variables
        VarMax = UB;         % Upper Bound of Variables

        checkBox=zeros(1020,501);
        %% PSO Parameters

        MaxIt = 50;      % Maximum Number of Iterations

        nPop = 250;        % Population Size (Swarm Size)

        % % Constriction Coefficients
        % phi1 = 2.05;
        % phi2 = 2.05;
        % phi = phi1+phi2;
        % chi = 2/(phi-2+sqrt(phi^2-4*phi));
        % w = chi;          % Inertia Weight
        % wdamp = 1;        % Inertia Weight Damping Ratio
        % c1 = chi*phi1;    % Personal Learning Coefficient
        % c2 = chi*phi2; 
        % PSO Parameters
        w = 1;            % Inertia Weight
        wdamp = 0.99;     % Inertia Weight Damping Ratio
        c1 = 1.5;         % Personal Learning Coefficient
        c2 = 2.0;         % Global Learning Coefficient
        VelMax = 0.1*(VarMax-VarMin);
        VelMin = -VelMax;

        CostFunction = @(x) CostBuy(x,DFP,MRP,Duration,NumMaterial,MatPro,TFR,OFR,MatCost,OptScenarioNum ,StockLength ,StockWidth ,StockHeight,B,ProfSurArea,MaxSQ);
        empty_particle.Position = [];
        empty_particle.Cost = [];
        empty_particle.Velocity = [];
        empty_particle.Best.Position = [];
        empty_particle.Best.Cost = [];
        particle = repmat(empty_particle, nPop, 1);
        
        GlobalBest.Cost = inf;
        i=0;
        for iii = 1:200
            for ii=1:5
                i=i+1;
                for m = 1:NumMaterial
                    for t=1:Duration

                            if t==1
                                particle(i).Position((((2*m)+1-3)*(Duration))+t)=round((LB((((2*m)+1-3)*(Duration))+t)+rand*(UB((((2*m)+1-3)*(Duration))+t)-(LB((((2*m)+1-3)*(Duration))+t))))*1000)/1000;
                            else
                                if t+MatPro{m}{4}<208
                                    tempMin=LB((((2*m)+1-3)*(Duration))+t)-sum(particle(i).Position((((2*m)+1-3)*(Duration))+1:(((2*m)+1-3)*(Duration))+t-1)) + (sum(MRP(m,1:t+MatPro{m}{4}-1))/1000);

                                    if tempMin<0
                                        tempMin=0;
                                    end
                                    m1=(MaxSQ(m)/1000)+(sum(MRP(m,1:t+MatPro{m}{4}-1))/1000)-sum(particle(i).Position((((2*m)+1-3)*(Duration))+1:(((2*m)+1-3)*(Duration))+t-1));
                                    m2=MaxQMat{m}/1000;
                                    m3=tempMin+rand()*(((TQM(m)*MatPro{m}{9}/1000)-sum(particle(i).Position((((2*m)+1-3)*(Duration))+1:(((2*m)+1-3)*(Duration))+t-1)))-(tempMin));
                                    v1=min(m1,m2);
                                    v11=min(v1,m3);
                                    v111=max(0,v11);
                                    fv=min(v111,VarMax((((2*m)+1-3)*(Duration))+t));
                                    
                                    particle(i).Position((((2*m)+1-3)*(Duration))+t)=(round(fv*1000))/1000;
                                else
                                    particle(i).Position((((2*m)+1-3)*(Duration))+t)=0;
                                end
                            end
                            if ii==1
                                particle(i).Position((((2*m)+2-3)*(Duration))+t)=0;
                            elseif ii==2
                                particle(i).Position((((2*m)+2-3)*(Duration))+t)=1;
                            else
                                particle(i).Position((((2*m)+2-3)*(Duration))+t)=round(((LB((((2*m)+2-3)*(Duration))+t)+rand()*(UB((((2*m)+2-3)*(Duration))+t)-LB((((2*m)+2-3)*(Duration))+t)))*100))/100;
                                
                            end
                    end
                end
                particle(i).Cost = CostFunction(particle(i).Position);
                checkBox(i,1)= particle(i).Cost;
            end
        end
        
        for i=1001:1020
            for n =1:nVar
                particle(i).Position(n)=VarMin(n)+rand()*(VarMax(n)-VarMax(n));
            end
            particle(i).Cost = CostFunction(particle(i).Position);
            checkBox(i,1)= particle(i).Cost;
        end
        
        for i =1:nPop
            particle(i).Velocity = zeros(VarSize);

            % Update Personal Best
            particle(i).Best.Position = particle(i).Position;
            particle(i).Best.Cost = particle(i).Cost;

            % Update Global Best
            if particle(i).Best.Cost<GlobalBest.Cost

                GlobalBest = particle(i).Best;

            end
            
        end
        
        BestCost = zeros(MaxIt, 1);
        %% PSO Main Loop
        checktoStop=0;
        for it = 1:MaxIt

            for i = 1:nPop

                % Update Velocity
                particle(i).Velocity = w*particle(i).Velocity ...
                    +c1*rand(VarSize).*(particle(i).Best.Position-particle(i).Position) ...
                    +c2*rand(VarSize).*(GlobalBest.Position-particle(i).Position);

                % Apply Velocity Limits
                particle(i).Velocity = max(particle(i).Velocity, VelMin);
                particle(i).Velocity = min(particle(i).Velocity, VelMax);

                % Update Position
                particle(i).Position = particle(i).Position + particle(i).Velocity;

                % Velocity Mirror Effect
                IsOutside = (particle(i).Position<VarMin | particle(i).Position>VarMax);
                particle(i).Velocity(IsOutside) = -particle(i).Velocity(IsOutside);

                % Apply Position Limits

                for n=1:nVar
                    WhichItem=mod(n,2*Duration);
                    if WhichItem>Duration
                        particle(i).Position(n) = round(max(particle(i).Position(n), VarMin(n))*100)/100;
                        particle(i).Position(n) = round(min(particle(i).Position(n), VarMax(n))*100)/100;
                    else
                        if WhichItem==1
                            particle(i).Position(n) = round(max(particle(i).Position(n), VarMin(n))*1000)/1000;
                            particle(i).Position(n) = round(min(particle(i).Position(n), VarMax(n))*1000)/1000;
                        else
                            if WhichItem+MatPro{m}{4}<208
                                MaterialID=ceil(n/(2*Duration));
                                tempMin1=VarMin(n)-sum(particle(i).Position((((2*MaterialID)+1-3)*(Duration))+1:(((2*MaterialID)+1-3)*(Duration))+WhichItem-1)) + (sum(MRP(MaterialID,1:WhichItem+MatPro{MaterialID}{4}-1))/1000);

                                if tempMin1<0
                                    tempMin1=0;
                                end

                                totalBuy=sum(particle(i).Position((((2*MaterialID)+1-3)*(Duration))+1:(((2*MaterialID)+1-3)*(Duration))+WhichItem-1));
                                MaxValue=min(MaxSQ(MaterialID)/1000-totalBuy+(sum(MRP(MaterialID,1:WhichItem+MatPro{MaterialID}{4}-1)))/1000,(TQM(MaterialID)*MatPro{MaterialID}{9}/1000)-totalBuy);


                                particle(i).Position(n) = round(max(particle(i).Position(n), tempMin1)*1000)/1000;
                                particle(i).Position(n) = round(min(particle(i).Position(n), min(VarMax(n),MaxValue))*1000)/1000;
                            else
                                particle(i).Position(n)=0;
                            end
                        end

                    end
                end
                % Evaluation
                particle(i).Cost = CostFunction(particle(i).Position);
               
                checkBox(i,it+1)= particle(i).Cost;
                % Update Personal Best
                if particle(i).Cost<particle(i).Best.Cost

                    particle(i).Best.Position = particle(i).Position;
                    particle(i).Best.Cost = particle(i).Cost;

                    % Update Global Best
                    if particle(i).Best.Cost<GlobalBest.Cost

                        GlobalBest = particle(i).Best;

                    end

                end

            end

            BestCost(it) = GlobalBest.Cost;

            disp(['IterationBuy ' num2str(it) ': Best Cost = ' num2str(BestCost(it))]);

            w = w*wdamp;
%             if it>1
%                 if BestCost(it)==BestCost(it-1)
%                     checktoStop = checktoStop +1;
%                 else
%                     checktoStop=0;
%                 end
%             end
%             if checktoStop>5
%                 break
%             end

        end

        BestSol = GlobalBest;

%         figure;
%         %plot(BestCost, 'LineWidth', 2);
%         semilogy(BestCost, 'LineWidth', 2);
%         xlabel('Iteration');
%         ylabel('Best Cost');
%         grid on;


        

        %resualt
        bestXBuy=BestSol.Position;
        BestCostTotal = BestSol.Cost;
        z{1}=DFP+BestCostTotal;
        z{2}=bestXBuy;
    end


end



% %validation
% 
% function z = CostTime(x,MaxQMat,NumTask,LDT,Duration,D,NumMaterial,UQ,MatPro,DDPC,TFR,OFR,DPC,MatCost,OptScenarioNum, WESTask ,WEFTask ,WLSTask ,WLFTask ,TQM ,Predecessors,StockLength ,StockWidth ,StockHeight,B,ProfSurArea)
%     z=[];
%     
%     digits(4);
%     % % Check constraint
%     SumCposTime = constraintTime(x,OptScenarioNum ,WESTask ,WEFTask ,WLSTask ,WLFTask ,Predecessors ,NumTask ,Duration ,D ,NumMaterial ,UQ ,MatPro ,ProfSurArea ,StockLength ,StockWidth ,StockHeight);
%     part4:hazine takhir
%     if SumCposTime>0
%         z{1}=99999999999999999999999999999999999999999999999999999999999999999;
%         z{2}=zeros(NumMaterial,Duration);
%     else
% 
%         if (x(NumTask)+D(NumTask)) >(days(DDPC-LDT)+1)
%             temp_dif_T = string(x(NumTask)+D(NumTask) - (days(DDPC-LDT)+1));
%             temp=textscan(temp_dif_T,'%f');
%             Diff = double(temp{1});
%             DFP = Diff * DPC;
%         else
%             DFP=0;
%         end
% 
%         MRP = zeros(NumMaterial,Duration);
%         Q=[];
%         for t = 1:Duration
%         dar har roz yek matrix q ba tedad satre barabar ba material va sotone
%         barabar ba tedad failat ha ijad mikonim ta mizane morede niaz material
%         moshakhas shavad
%             Q{t}=zeros(NumMaterial,NumTask);
%             for n = 1:NumTask
%                 if (x(n)<=t) && (t<=x(n)+D(n)-1)
%                     for m = 1:NumMaterial
%                         Q{t}(m,n) = Q{t}(m,n) + UQ(m,n)*MatPro{m}{9};
%                     end
%                 end 
%             end
%             for m = 1:NumMaterial
%                for n = 1:NumTask
%                    MRP(m,t) = MRP(m,t) + Q{t}(m,n);
%                end
%             end
%         end
%         
%         max capacity Storage
%         MaxSQ=zeros(NumMaterial,1);
%         for m=1:NumMaterial
%             Ha=floor(StockHeight{OptScenarioNum}{m}/MatPro{m}{11});
%             lengthUnit dar rastaye lenghtStorage
%             Wa=floor(StockWidth{OptScenarioNum}{m}/MatPro{m}{10});
%             Lt=StockLength{OptScenarioNum}{m}/MatPro{m}{12};
%             La=floor(Lt);
%             Let=Lt-La;
%             FirstUnitCap=Wa*La*Ha;
%             if Let==0
%                 SecondUnitCap=0;
%             else
%                 We=floor(Let/MatPro{m}{10});
%                 Le=floor(StockWidth{OptScenarioNum}{m}/MatPro{m}{12});
%                 SecondUnitCap=We*Le*Ha;
%             end
%             TotalUnitCap=FirstUnitCap+SecondUnitCap;
% 
%             if MatPro{m}{8} == "NoProfile"
%                 MaxSQ(m)=TotalUnitCap*MatPro{m}{9};
%             elseif MatPro{m}{8}(1:2) ~= "PL"
%                 MaxSQ(m)=TotalUnitCap*(MatPro{m}{9}*ProfSurArea(m)*MatPro{m}{12});
%             elseif MatPro{m}{8}(1:2) == "PL"
%                 MaxSQ(m)=TotalUnitCap*(MatPro{m}{9}*MatPro{m}{10}*MatPro{m}{11}*MatPro{m}{12});
%             end
%         end
%         
%         lastIndexX=(2*NumMaterial +2 - 2)*Duration;
%         LB=[];
%         UB=[];
%         for m = 1:NumMaterial
%             for p = 1:2
%                 for t = 1:Duration
%                     if p==1
%                         
%                         if (t>1) && (t+MatPro{m}{4}<208)
%                             UB = [UB min(MaxSQ(m),min(MaxQMat{m},(TQM(m)*MatPro{m}{9}-sum(MRP(m,1:t+MatPro{m}{4}-1)))))/1000];
%                             LB = [LB MRP(m,t+MatPro{m}{4})/1000]; 
%                         elseif t==1
%                             UB = [UB min(MaxSQ(m),min(MaxQMat{m},TQM(m)*MatPro{m}{9}))/1000];
%                             LB = [LB MRP(m,t+MatPro{m}{4})/1000]; 
%                         else
%                             UB = [UB 0];
%                             LB = [LB 0]; 
%                         end
% 
%                     else
%                         LB=[LB 0];
%                         UB = [UB 1];
%                     end
%                 end
%             end
%         end
% 
%         % Problem Definition
% 
% 
%         nvars=lastIndexX;
%         nVar = lastIndexX;            % Number of Decision Variables
% 
%         VarSize = [1 nVar];   % Size of Decision Variables Matrix
% 
%         VarMin = LB;         % Lower Bound of Variables
%         VarMax = UB;         % Upper Bound of Variables
% 
%         CostFunction = @(x) CostBuy(x,DFP,MRP,Duration,NumMaterial,MatPro,TFR,OFR,MatCost,OptScenarioNum ,StockLength ,StockWidth ,StockHeight,B,ProfSurArea,MaxSQ);
%         empty_particle.Position = [];
%         empty_particle.Cost = [];
%         empty_particle.Velocity = [];
%         empty_particle.Best.Position = [];
%         empty_particle.Best.Cost = [];
%         particle = repmat(empty_particle, 1, 1);
%         
% 
%         particle(1).Position=zeros(1,3312);
%         for i = 1:1
% 
%                 for m = 1:NumMaterial
%                     if (m==5) || (m==6) || (m==8)
%                         t1=1;
%                         extra=0;
%                         for t=1:Duration
%                             if t1<=t
%                                 if t1==1
%                                     if sum(MRP(m,t1:t))>24000
%                                         particle(i).Position((((2*m)+1-3)*(Duration))+t1)=24;
%                                         particle(i).Position((((2*m)+2-3)*(Duration))+t1)=1;
%                                         extra=max(0,sum(MRP(m,t1+1:t))+extra-12000);
%                                         t1=t+1;
%                                     end
%                                 else
%                                     if sum(MRP(m,t1:t))+extra>24000
%                                         particle(i).Position((((2*m)+1-3)*(Duration))+t1-MatPro{m}{4})=24;
%                                         particle(i).Position((((2*m)+2-3)*(Duration))+t1-MatPro{m}{4})=1;
%                                         extra=max(0,sum(MRP(m,t1+1:t))+extra-12000);
%                                         t1=t+1;
%                                     elseif (sum(MRP(m,t1:t))+extra<24000) && (t==Duration)
%                                         particle(i).Position((((2*m)+1-3)*(Duration))+t1-MatPro{m}{4})=(sum(MRP(m,t1:t))+extra)/1000;
%                                         particle(i).Position((((2*m)+2-3)*(Duration))+t1-MatPro{m}{4})=1;
%                                         t1=t+1;
%                                     end
%                                 end
%                             end
% 
%                         end
%                         
%                     elseif m==1
%                         t1=1;
%                         extra=0;
%                         for t=1:Duration
%                             if t1<=t
%                                 if t1==1
%                                     if sum(MRP(m,t1:t))>40000
%                                         particle(i).Position((((2*m)+1-3)*(Duration))+t1)=40;
%                                         particle(i).Position((((2*m)+2-3)*(Duration))+t1)=0.5;
%                                         extra=sum(MRP(m,t1:t))-40000;
%                                         t1=t+1;
%                                     end
%                                 else
%                                     if sum(MRP(m,t1:t))+extra>40000
%                                         particle(i).Position((((2*m)+1-3)*(Duration))+t1-MatPro{m}{4})=40;
%                                         particle(i).Position((((2*m)+2-3)*(Duration))+t1-MatPro{m}{4})=0.5;
%                                         extra=max(0,sum(MRP(m,t1:t))+extra-40000);
%                                         t1=t+1;
%                                     elseif (sum(MRP(m,t1:t))+extra<40000) && (t==Duration)
%                                         particle(i).Position((((2*m)+1-3)*(Duration))+t1-MatPro{m}{4})=(sum(MRP(m,t1:t))+extra)/1000;
%                                         particle(i).Position((((2*m)+2-3)*(Duration))+t1-MatPro{m}{4})=1;
%                                         t1=t+1;
%                                     end
%                                 end
%                             end
% 
%                         end
%                         
%                     
%                         
%                     elseif (m==3) || (m==4) || (m==7)
%                         for t=1:20:Duration
%                             if t+20<Duration
%                                 particle(i).Position((((2*m)+1-3)*(Duration))+t)=sum(MRP(m,t+MatPro{m}{4}:t+MatPro{m}{4}+19))/1000;
%                             else
%                                 particle(i).Position((((2*m)+1-3)*(Duration))+t)=sum(MRP(m,t+MatPro{m}{4}:Duration))/1000;
%                             end
%                             particle(i).Position((((2*m)+2-3)*(Duration))+t)=1;
%                         end
%                     elseif m==2
%                         t1=1;
%                         extra=0;
%                         for t=1:Duration
%                             if t1<=t
%                                 if t1==1
%               
%                                     if sum(MRP(m,t1:t))>12000
%                                         particle(i).Position((((2*m)+1-3)*(Duration))+t1)=12;
%                                         particle(i).Position((((2*m)+2-3)*(Duration))+t1)=1;
%                                         extra=max(0,sum(MRP(m,t1+1:t))-12000);
%                                         t1=t+1;
%                                     end
%                                 else
%                                     if sum(MRP(m,t1:t))+extra>12000
%                                         particle(i).Position((((2*m)+1-3)*(Duration))+t1-MatPro{m}{4})=12;
%                                         particle(i).Position((((2*m)+2-3)*(Duration))+t1-MatPro{m}{4})=1;
%                                         extra=max(0,sum(MRP(m,t1+1:t))+extra-12000);
%                                         t1=t+1;
%                                     elseif (sum(MRP(m,t1:t))+extra<12000) && (t==Duration)
%                                         particle(i).Position((((2*m)+1-3)*(Duration))+t1-MatPro{m}{4})=(sum(MRP(m,t1:t))+extra)/1000;
%                                         particle(i).Position((((2*m)+2-3)*(Duration))+t1-MatPro{m}{4})=1;
%                                         t1=t+1;
%                                     end
%                                 end
%                             end
% 
%                         end
%                         JIT
%                     elseif m==2
%                         for t=1:Duration
%                             if t+MatPro{m}{4}-1<Duration
%                                 particle(i).Position((((2*m)+1-3)*(Duration))+t)=MRP(m,t+MatPro{m}{4}-1)/1000;
%                                 particle(i).Position((((2*m)+2-3)*(Duration))+t)=1;
%                             else
%                                 particle(i).Position((((2*m)+1-3)*(Duration))+t)=0;
%                                 particle(i).Position((((2*m)+2-3)*(Duration))+t)=1;
%                             end
%                         end
%             
%                     end
%                     
%                 end
%                 particle(i).Cost = CostFunction(particle(i).Position);
%         end
%         
%         
%         
% 
%         BestSol = particle(1);
% 
% 
% 
%         
% 
%         resualt
%         bestXBuy=BestSol.Position;
%         BestCostTotal = BestSol.Cost;
%         z{1}=DFP+BestCostTotal;
%         z{2}=bestXBuy;
%     end


% end