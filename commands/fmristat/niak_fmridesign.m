function X_cache = niak_fmridesign(opt)

% _________________________________________________________________________
% SUMMARY NIAK_MAKE_TRENDS
%
% Create temporal an spatial trends to be include in the design matrix.
% 
% SYNTAX:
% Trend = NIAK_FMRIDESIGN(OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% OPT         
%       structure with the following fields :
%
%       FRAME_TIMES is a row vector of frame acquisition times in seconds. 
%       With just the frametimes, it gives the hemodynamic response function.
%
%       SLICE_TIMES is a row vector of relative slice acquisition times,
%       i.e. absolute acquisition time of a slice is FRAME_TIMES+SLICE_TIMES.
%       Default is 0.
%       
%       EVENTS is a matrix whose rows are events and whose columns are:
%       1. id - an integer from 1:(number of events) to identify event type;
%       2. times - start of event, synchronised with frame and slice times;
%       3. durations (optional - default is 0) - duration of event;
%       4. heights (optional - default is 1) - height of response for event.
%       For each event type, the response is a box function starting at the 
%       event times, with the specified durations and heights, convolved with 
%       the hemodynamic response function (see below). If the duration is zero, 
%       the response is the hemodynamic response function whose integral is 
%       the specified height - useful for `instantaneous' stimuli such as visual 
%       stimuli. The response is then subsampled at the appropriate frame and 
%       slice times to create a design matrix for each slice, whose columns 
%       correspond to the event id number. EVENT_TIMES=[] will ignore event 
%       times and just use the stimulus design matrix S (see next). 
%       Default is [1 0].
%
%       S: 
%       Events can also be supplied by a stimulus design matrix, hose rows 
%       are the frames, and column are the event types. Events are created 
%       for each column, beginning at the frame time for each row of S, 
%       with a duration equal to the time to the next frame, and a height
%       equal to the value of S for that row and column. Note that a
%       constant term is not usually required, since it is removed by the
%       polynomial temporal trend terms. Default is [].
%
% _________________________________________________________________________
% OUTPUTS:
%
% X_CACHE 
%         structure with the following fields :

%         TR:
%         average time between frames (secs). 
% 
%         X: 
%         A cache of the design matrices stored as a 4D array. 
%         Dim 1: frames; Dim 2: response variables; Dim 3: 4 values, 
%         corresponding to the stimuli convolved with: hrf, derivative of 
%         hrf, first and second spectral basis functions over the range in 
%         SHIFT; Dim 4: slices. 
%
%         W: 
%         A 3D array of coefficients of the basis functions in X_CACHE.X.
%         Dim 1: frames; Dim 2: response variables; Dim 3: 5 values: 
%         coefficients of the hrf and its derivative, coefficients of the 
%         first and second spectral basis functions, shift values.
%############################################################################
% COPYRIGHT:   Copyright 2002 K.J. Worsley
%              Department of Mathematics and Statistics,
%              McConnell Brain Imaging Center, 
%              Montreal Neurological Institute,
%              McGill University, Montreal, Quebec, Canada. 
%              worsley@math.mcgill.ca, liao@math.mcgill.ca
%
%              Permission to use, copy, modify, and distribute this
%              software and its documentation for any purpose and without
%              fee is hereby granted, provided that the above copyright
%              notice appear in all copies.  The author and McGill University
%              make no representations about the suitability of this
%              software for any purpose.  It is provided "as is" without
%              express or implied warranty.
%##########################################################################


% Setting up default
gb_name_structure = 'opt';
gb_list_fields = {'frametimes','slicetimes','events','S'};
gb_list_defaults = {NaN,0,[1 0],[]};
niak_set_defaults


hrf_parameters = [5.4 5.2 10.8 7.35 0.35];
shift = [-4.5 4.5];

n = length(opt.frametimes);
numslices = length(opt.slicetimes);
events = opt.events;

% Keep time points that are not excluded:

if ~isempty(events)
   numevents=size(events,1);
   eventid=events(:,1);
   numeventypes=max(eventid);
   eventime=events(:,2);
   if size(events,2)>=3
      duration=events(:,3);
   else
      duration=zeros(numevents,1);
   end
   if size(events,2)>=4
      height=events(:,4);
   else
      height=ones(numevents,1);
   end
   mineventime=min(eventime);
   maxeventime=max(eventime+duration);
else
   numeventypes=0;
   mineventime=Inf;
   maxeventime=-Inf;
end

if ~isempty(S)
   numcolS=size(S,2);
else
   numcolS=0;
end

% Set up response matrix:

dt=0.02;
startime=min(mineventime,min(frametimes)+min([slicetimes 0]));
finishtime=max(maxeventime,max(frametimes)+max([slicetimes 0]));
numtimes=ceil((finishtime-startime)/dt)+1;
numresponses=numeventypes+numcolS;
response=zeros(numtimes,numresponses);

if ~isempty(events)
   height=height./(1+(duration==0)*(dt-1));
   for k=1:numevents
      type=eventid(k);
      n1=ceil((eventime(k)-startime)/dt)+1;
      n2=ceil((eventime(k)+duration(k)-startime)/dt)+(duration(k)==0);
      if n2>=n1
         response(n1:n2,type)=response(n1:n2,type)+height(k)*ones(n2-n1+1,1);
      end
   end
end

if ~isempty(S)
   for j=1:numcolS
      for i=find(S(:,j)')
         n1=ceil((frametimes(i)-startime)/dt)+1;
         if i<n
            n2=ceil((frametimes(i+1)-startime)/dt);
         else
            n2=numtimes;
         end
         if n2>=n1 
            response(n1:n2,numeventypes+j)= ...
               response(n1:n2,numeventypes+j)+S(i,j)*ones(n2-n1+1,1);
         end
      end
   end
end

hrf_parameters = repmat(hrf_parameters,numresponses,1);
shift = repmat(shift,numresponses,1);


eventmatrix=zeros(numtimes,numresponses,4);
nd=41;
X_cache.W=zeros(nd,numresponses,5);

for k=1:numresponses
   Delta1=shift(k,1);
   Delta2=shift(k,2);
   peak1=hrf_parameters(k,1);
   fwhm1=hrf_parameters(k,2);
   peak2=hrf_parameters(k,3);
   fwhm2=hrf_parameters(k,4);
   dip=hrf_parameters(k,5);
   numlags=ceil((max(peak1+3*fwhm1,peak2+3*fwhm2)+Delta2-Delta1)/dt)+1;
   numlags=min(numlags,numtimes);
   time=(0:(numlags-1))'*dt;

   % Taylor:
   if isstruct(hrf_parameters)
      hrf=interp1(hrf_parameters.T(k,:),hrf_parameters.H(k,:),time,'spline',0);
      d_hrf=-gradient(hrf,dt);
   else
      tinv=(time>0)./(time+(time<=0));
      if peak1>0 & fwhm1>0
         alpha1=peak1^2/fwhm1^2*8*log(2);
         beta1=fwhm1^2/peak1/8/log(2);
         gamma1=(time/peak1).^alpha1.*exp(-(time-peak1)./beta1);
         d_gamma1=-(alpha1*tinv-1/beta1).*gamma1;
      else 
         gamma1=min(abs(time-peak1))==abs(time-peak1);
         d_gamma1=zeros(numlags,1);
      end
      if peak2>0 & fwhm2>0
         alpha2=peak2^2/fwhm2^2*8*log(2);
         beta2=fwhm2^2/peak2/8/log(2);
         gamma2=(time/peak2).^alpha2.*exp(-(time-peak2)./beta2);
         d_gamma2=-(alpha2*tinv-1/beta2).*gamma2;
      else 
         gamma2=min(abs(time-peak2))==abs(time-peak2);
         d_gamma2=zeros(numlags,1);
      end
      hrf=gamma1-dip*gamma2;
      d_hrf=d_gamma1-dip*d_gamma2;
   end
   HS=[hrf d_hrf]/sum(hrf);
   temp=conv2(response(:,k),HS);
   eventmatrix(:,k,1:2)=temp(1:numtimes,:);
   
   % Shifted hrfs:
   H=zeros(numlags,nd);
   delta=((1:nd)-1)/(nd-1)*(Delta2-Delta1)+Delta1;
   for id=1:nd
      if isstruct(hrf_parameters)
         t=time+Delta1-delta(id);
         hrf=interp1(hrf_parameters.T(k,:),hrf_parameters.H(k,:),t,'spline',0);
      else
         t=(time+Delta1-delta(id)).*((time+Delta1)>delta(id));
         if peak1>0 & fwhm1>0
            gamma1=(t/peak1).^alpha1.*exp(-(t-peak1)./beta1);
         else 
            gamma1=min(abs(t-peak1))==abs(t-peak1);
         end
         if peak2>0 & fwhm2>0
            gamma2=(t/peak2).^alpha2.*exp(-(t-peak2)./beta2);
         else 
            gamma2=min(abs(t-peak2))==abs(t-peak2);
         end
         hrf=gamma1-dip*gamma2;
      end
      H(:,id)=hrf/sum(hrf);
   end
   
   % Taylor coefs:
   origin=-round(Delta1/dt);
   HS0=[zeros(origin,2); HS(1:(numlags-origin),:)];
   WS=pinv(HS0)*H;
   X_cache.W(:,k,1:2)=WS';
   prcnt_var_taylor=sum(sum(H.*(HS0*WS)))/sum(sum(H.*H))*100;

   % svd:
   [U,SS,V]=svd(H,0);
   prcnt_var_spectral=(SS(1,1)^2+SS(2,2)^2)/sum(diag(SS).^2)*100;
   sumU=sum(U(:,1));
   US=U(:,1:2)/sumU;
   WS=V(:,1:2)*SS(1:2,1:2)*sumU;
   if delta*WS(:,2)<0
      US(:,2)=-US(:,2);
      WS(:,2)=-WS(:,2);
   end
   temp=conv2(response(:,k),US);
   eventmatrix(:,k,3:4)=temp((1:numtimes)-round(Delta1/dt),:);
   X_cache.W(:,k,3:4)=WS;
   X_cache.W(:,k,5)=delta';
   
   if ~all(WS(:,1)>0)
      fprintf(['Warning: use only for magnitudes, not delays \n first coef not positive for stimulus ' num2str(k)]);
   end
   cubic_coef=pinv([delta' delta'.^3])*(WS(:,2)./WS(:,1));
   if prod(cubic_coef)<0
      fprintf(['\nWarning: use only for magnitudes, not delays \n svd ratio not invertible for stimulus ' num2str(k)]);
   end
end 

X_cache.X=zeros(n,numresponses,4,numslices);

for slice = 1:numslices
   subtime=ceil((frametimes+slicetimes(slice)-startime)/dt)+1;
   X_cache.X(:,:,:,slice)=eventmatrix(subtime,:,:);
end

X_cache.TR=(max(frametimes)-min(frametimes))/(length(frametimes)-1);


