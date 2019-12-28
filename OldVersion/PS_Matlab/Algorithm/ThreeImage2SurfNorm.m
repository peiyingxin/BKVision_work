function[N1,N2,N3] = ThreeImage2SurfNorm(R1,R2,R3,L)
%����  R1,R2,R3 �ֱ�����������Ͷ��ʱ����õĻҶ�ͼ����
%      L  ��Դ�������
%���  (N1,N2,N3)�Ǳ��浥λ����ľ���
    [h1,w1] =size(R1);
    [h2,w2] =size(R2);
    [h3,w3] =size(R3);
    N1 = zeros(h1,w1);
    N2 = zeros(h1,w1);
    N3 = zeros(h1,w1);
    if h1~= h2 || h1~= h3 || h2 ~= h3 ||w1~= w2 || w1~= w3 || w2 ~= w3 
        return
    end
    invL=inv(double(L));
    surfnorm=double(zeros(3,1));%��ʱ����ķ�����
    for i = 1:h1
        for j = 1:w1
            surfnorm=invL*[R1(i,j);R2(i,j);R3(i,j)];
            normsuf=norm(surfnorm);
            if normsuf~=0
                surfnorm=surfnorm/norm(surfnorm);
                N1(i,j) =surfnorm(1,1);
                N2(i,j) =surfnorm(2,1);   
                N3(i,j) =surfnorm(3,1);
            else
                N1(i,j) =0;
                N2(i,j) =0;   
                N3(i,j) =1;
            end
        end
    end       
end