function [Z,IterativeInfoOut] = MultiScaleIntegrate(P,Q,Z0,IterativeInfo,borderInfo,hFigure)
    tic;
    [Z,IterativeInfoOut0] = MultiScaleRecursion(P,Q,Z0,IterativeInfo,borderInfo,hFigure);
    timeVal=toc;
    IterativeInfoOut={'time','timelist','timeslist','errZList','errPQList';...
                      timeVal,IterativeInfoOut0{:}};
end

function [Z,IterativeInfoOut] = MultiScaleRecursion(P,Q,Z0,IterativeInfo,borderInfo,hFigure)
%MultiScaleOptimize: Optimize Z from P��Zx Q��Zy
%Version:2.0, Author;WANG lei, Date:2015.6.10
%Input:
%  P,Q:P��Zx Q��Zy
%  Z0:Initial Surface
%  IterativeInfo: {endTimes,endErrZ,endErrPQ}
%      Times: Iterative Times -1 unlimited       
%      errZ:  errZ(Z(x,y))=mean(mean((Zk - Zk_1))  -1 unlimited
%      errPQ: errPQ(Z(x,y))=mean(mean((Zx-P).*(Zx-P)+(Zy-Q).*(Zy-Q)) -1 unlimited
%  borderInfo: 0: border free; 1: border flat
%Output:
%  Z: depth matrix
%  IterativeInfoOut: {time,[times],errZ,errPQ};
%Reference:
% (Code)Horn, B. K. P., & Brooks, M. J. (1985). The variational approach to shape from shading. Computer Vision, Graphics, and Image Processing, 32(1), 142. http://doi.org/10.1016/0734-189X(85)90010-6
%       Saracchini, R. F. V., Stolfi, J., Leit?o, H. C. G., Atkinson, G. a., & Smith, M. L. (2012). A robust multi-scale integration method to obtain the depth from gradient maps. Computer Vision and Image Understanding, 116(8), 882�C895. http://doi.org/10.1016/j.cviu.2012.03.006
%Algorithm:
%  Solve minimize functional:
%                           w h
%  minimize: errPQ(Z(x,y))=�ơ�(Zx(x,y)-P(x,y))^2+(Zy(x,y)-Q(x,y))^2
%                         x=1 y=1
%  If:       E=(Zx(x,y)-P(x,y))^2+(Zy(x,y)-Q(x,y))^2
%  Exist Euler-Lagrange equation:
%            ?E/?Z - d(?E/?Zx)/dx - d(?E/?Zy)/dy=0
%  Since  ?E/?Z=0; d(?E/?Zx)/dx=Zx(x,y)-P(x,y); d(?E/?Zy)/dy=Zy(x,y)-Q(x,y)
%  In discrete space the 2d poisson equation (5) could be described as 
%      a "five point difference format":
%
%                   Z(x,y-1)
%         �𩤩������������񩤩�������������
%         ��             ��             ��
%         ��             ��             ��
%         ��             �� -Q(x,y-0.5) ��
%         ��             ��             ��
%         ��             ��4*Z(x,y)     ��
% Z(x-1,y)�񩤩������������񩤩��D���������� Z(x+1,y)
%         �� -P(x-0.5,y) ��  P(x+0.5,y) ��
%         ��             ��             ��
%         ��             �� Q(x,y+0.5)  ��
%         ��             ��             ��
%         ��             ��             ��
%         �𩤩������������񩤩�������������
%                   Z(x,y+1)
%
%    mZ(x,y)=0.25*(Z(x-1,y)+Z(x+1,y)+Z(x,y-1)+Z(x,y+1)...
%                 +P(x-0.5,y)-P(x+0.5,y)+Q(x,y-0.5)-Q(x,y+0.5))
%  MultiScale logic 
%                     a                    a'
%         �񩤩��������𩤩��������񩤩���������
%         ��         ��         ��          ��
%         ��         ��         ��          ��
%         ��         ��c        ��          ��
%       b �𩤩��������𩤩��������𩤩���������c'
%         ��         ��         ��          ��
%         ��         ��         ��          ��
%         ��         ��         ��          ��
%         �񩤩��������𩤩��������񩤩���������
%         ��         ��         ��          ��
%         ��         ��         ��          ��
%         ��         ��         ��          ��
%       b'�𩤩��������𩤩��������𩤩���������c'''

    
%% Initial
    [hP,wP]=size(P);
    [hQ,wQ]=size(Q);
    if(hP~=hQ+1||wP+1~=wQ)
        error('Input parameter number error');
    end
    h=hP;
    w=wQ;
    if isnan(Z0)
        Z0=zeros(h,w,'double');
    else
        [hZ,wZ]=size(Z0);
        if h~=hZ || w~=wZ
            error('Matrix Z0 size not fit!');
        end
    end
    [hZ,wZ]=size(Z0);
    Z=Z0;
    if iscell(IterativeInfo)
        [hIterativeInfo,wIterativeInfo]=size(IterativeInfo);
        if 1~=hIterativeInfo || 4~=wIterativeInfo
            error('IterativeInfo should be {endTimes,endErrZ,endErrPQ,minSize}');
        end
        endTimes=int64(IterativeInfo{1});
        endErrZ=double(IterativeInfo{2});
        endErrPQ=double(IterativeInfo{3});
        minSize=double(IterativeInfo{4});
    else
        error('IterativeInfo should be Cell');
    end

    borderInfo;
%% MultiScale recursion
    if minSize<4
        minSize=4;
    end
    IterativeInfoOut1=NaN;
%     tic;
    if hP>=minSize && wP>=minSize-1 && hQ>=minSize-1 && wQ>=minSize && hZ>=minSize && wZ>=minSize
        hOdd=mod(h,2);
        wOdd=mod(w,2);        
%         if hOdd || wOdd
%             error('hOdd or wOdd');
%         end
        subP=(P(1:2:hP,1:2:wP-1)+P(1:2:hP,2:2:wP))./2;
        subQ=(Q(1:2:hQ-1,1:2:wQ)+Q(2:2:hQ,1:2:wQ))./2;
        subZ0=Z0(1:2:hZ,1:2:wZ);
        %[hSZ,wSZ]=size(subZ0);
        [subZ,IterativeInfoOut1] = MultiScaleRecursion(subP,subQ,subZ0,IterativeInfo,borderInfo,hFigure);
        Z(1:2:h,1:2:w)=2*subZ;
        if wOdd==1
            % a
            Z(1:2:h,2:2:w-1)=0.5*(Z(1:2:h,1:2:w-2) +P(1:2:hP,1:2:wP-1)...
                                  +Z(1:2:h,3:2:w)   -P(1:2:hP,2:2:wP));
        else
            % a
            Z(1:2:h,2:2:w-2)=0.5*(Z(1:2:h,1:2:w-3) +P(1:2:hP,1:2:wP-2)...
                                  +Z(1:2:h,3:2:w-1) -P(1:2:hP,2:2:wP-1));          
            % a'
            Z(1:2:h,w)      =     Z(1:2:h,w-1)     +P(1:2:hP,wP);
        end
        if hOdd==1
            % b
            Z(2:2:h-1,1:2:w)=0.5*(Z(1:2:h-2,1:2:w) +Q(1:2:hQ-1,1:2:wQ)...
                                  +Z(3:2:h,1:2:w)   -Q(2:2:hQ,1:2:wQ));
        else
            % b
            Z(2:2:h-2,1:2:w)=0.5*(Z(1:2:h-3,1:2:w) +Q(1:2:hQ-2,1:2:wQ)...
                                  +Z(3:2:h-1,1:2:w) -Q(2:2:hQ-1,1:2:wQ));
            % b'
            Z(h,1:2:w)      =     Z(h-1,1:2:w)     +Q(hQ,1:2:wQ);
        end
        % c
        Z(2:2:h-1,2:2:w-1)=0.25* (Z(2:2:h-1,1:2:w-2)+P(2:2:hP-1,1:2:wP-1)...  %left
                                  +Z(2:2:h-1,3:2:w)  -P(2:2:hP-1,2:2:wP)...  %right
                                  +Z(1:2:h-2,2:2:w-1)+Q(1:2:hQ-1,2:2:wQ-1)...  %top
                                  +Z(3:2:h,2:2:w-1)  -Q(2:2:hQ,2:2:wQ-1));   %bottom
        if wOdd==0
            %c'
            Z(2:2:h-1,w) = (1/3)*(Z(2:2:h-1,w-1)    +P(2:2:hP-1,wP)...  %left
                                  +Z(1:2:h-2,w)      +Q(1:2:hQ-1,wQ)...  %top
                                  +Z(3:2:h,w)        -Q(2:2:hQ,wQ));   %bottom
        end  
        if hOdd==0
            %c''
            Z(h,2:2:w-1) = (1/3)*(Z(h,1:2:w-2)      +P(hP,1:2:wP-1)...  %left
                                  +Z(h,3:2:w)        -P(hP,2:2:wP)...  %right
                                  +Z(h-1,2:2:w-1)    +Q(hQ,2:2:wQ-1));  %top
        end    
        if hOdd==0 && wOdd==0
            %c'''
            Z(h,w)       = 0.5*  (Z(h,w-1)          +P(hP,wP)...  %left
                                  +Z(h-1,w)          +Q(hQ,wQ));  %top
        end
    else
        [Z,InfoOut_FourWayIntegrat] = FourWayIntegrate(P,Q);
    end
    %IterativeInfo2={endTimes,endErrZ,endErrPQ};
    %[Z,IterativeInfoOut2] = PossionSolverOptimize(P,Q,Z0,IterativeInfo2,borderInfo,NaN);
%     timeThisScale=toc;
    timeThisScale=0;
    if ishandle(hFigure)
        figure(hFigure);mesh(Z),title(['Z_ScaleSize=' num2str(hZ) '��' num2str(wZ) ]),axis equal;
    end
    
    %errZ=sqrt(mean(mean((Z-Z0).*(Z-Z0))));
    disP=Z(1:hZ,2:wZ)-Z(1:hZ,1:wZ-1)-P;
    disP=disP.*disP;
    errP=mean(mean(disP));
    disQ=Z(2:hZ,1:wZ)-Z(1:hZ-1,1:wZ)-Q;
    disQ=disQ.*disQ;
    errQ=mean(mean(disQ));
    errPQ=sqrt(errP+errQ);
    if ~iscell(IterativeInfoOut1)
        timelist=timeThisScale;
        timeslist=NaN;
        errZList=NaN;
        errPQList=errPQ;
    else
        timelist=[timeThisScale;IterativeInfoOut1{1}];
        timeslist=NaN;
        errZList=NaN;
        errPQList=[errPQ;IterativeInfoOut1{4}];
    end
    IterativeInfoOut={timelist,timeslist,errZList,errPQList};
end