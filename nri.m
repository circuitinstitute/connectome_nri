function [nriNet, precNet, recallNet, nriNeur, precNeur, recallNeur] = nri(C)% function [nriNet, precNet, recallNet, nriNeur, precNeur, recallNeur] = nri(C)%% This is a relatively fast implementation, but the code may be difficult% to understand since matrix operations have been leveraged for acceleration.% See the nri_slow() function for a version that is easier to read% and understand.%% Computes the Neural Reconstruction Index (NRI). Given a count table of% matching synapses, C (matched by location and polarity), for a reference% (ground truth) and test (automated segmentation) graph, calculate NRI for% individual neurons (local scores) and the full network (global score).%% The (i+1)th row and (j+1)th column of C should contain the number of matching% synapses for the ith reference neuron/object and the jth test% neuron/object. The 1st row and 1st column are not-founds (deletions in% (i+1,1) and insertions in (1,j+1)). The (1,1) entry of C should always be% 0 since a synapse cannot be both deleted and inserted.%% OUTPUTS% -------% nriNet:      A scalar value that is the global/network NRI score% precNet:     A scalar value that is the global/network Precision score% recallNet:   A scalar value that is the global/network Recall score% nriNeur:     A vector of NRI scores, one for each neuron. Values are ordered%              to match rows of the count table, C. The first value nriNeur(0)%              is set to NaN, since that row of C represents insertions, not a%              reference neuron.% precNeur:    A vector of Precision scores, one for each neuron. % recallNeur:  A vector of Recall scores, one for each neuron. %%% Matt Roos% JHU/APL% 11/7/2016% In comments below, cij is the (i,j)th element of C% [I,J] = size(C);  % I-1 reference neurons, J-1 test neurons% TP count for a neuron is sum of cij*(cij-1)/2, summed% over all j (all elements in a row excluding the first column, ci1)Z = C.*(C-1)/2;tpNeur = sum(Z(:,2:end),2);tpNeur(1) = 0; % don't count TPs in insertion row% FP count includes the sum of all possible products, cij*cpj, where the% sum excludes terms with p=i, or j=1.  The sum is divided by two so the% FPs aren't counted twice (i.e., once for each of two merged neurons). The% FP count also includes c1j-choose-2 summed over all j>1 (FPs due to pairs% of inserted terminals in row 1).FPij = bsxfun(@minus,sum(C,1),C).*C/2;FPij(1,:) = FPij(1,:) + Z(1,:);fpNeur = sum(FPij(:,2:end),2);% FN count includes [1] ci1*(ci1-1)/2 where ci1 is number of deleted% synapses and [2] all possible products, cij*cik (where cij and cik are% jth and kth elements of the ith row), excluding k,j=1 (the deletion% column) and j>=k (that is, we include cij*cik but not cik*cij and not% cij*cij).% Division by two in line below is because cij*cik and cik*cij are both% counted, but only one is wanted (i.e., j>=k)FNij = bsxfun(@minus,sum(C,2),C).*C./2;fnNeur = sum(FNij,2) + Z(:,1);fnNeur(1) = 0; % don't count FNs in insertion row% Compute NRI, precision, and recall for individual neuronsprecNeur = tpNeur./(tpNeur+fpNeur);recallNeur = tpNeur./(tpNeur+fnNeur);nriNeur = 2*tpNeur./(2*tpNeur+fpNeur+fnNeur); % same at 2*P*R/(P+R) but without undefined P or R problemnriNeur(1) = NaN; % insertion row, not a ground truth neuron% Compute NRI for full networkTP = nansum(tpNeur);FP = nansum(fpNeur);FN = nansum(fnNeur);precNet = TP / (TP + FP);recallNet = TP / (TP + FN);nriNet = 2*TP./(2*TP+FP+FN); % same at 2*P*R/(P+R) but without undefined P or R problemend % nri()% % %% SUBFUNCTIONS% %-----------------------------% function [I J] = itriu(sz, k)% % function [I J] = itriu(sz) % OR% % I = itriu(sz) OR% % % % Return the subindices [I J] (or linear indices I if single output call)% % in the purpose of extracting an upper triangular part of the matrix of% % the size SZ. Input k is optional shifting. For k=0, extract from the main% % diagonal. For k>0 -> above the diagonal, k<0 -> below the diagonal% %% % This returnd same as [...] = find(triu(ones(sz),k))% % - Output is a column and sorted with respect to linear indice% % - No interme.diate matrix is generated, that could be useful for large% %   size problem% % - Mathematically, A(itriu(size(A)) is called (upper) "half-vectorization"% %   of A % %% % Example:% %% % A = [ 7     5     4% %       4     2     3% %       9     1     9% %       3     5     7 ]% %% % I = itriu(size(A))  % gives [1 5 6 9 10 11]'% % A(I)                % gives [7 5 2 4  3  9]' OR A(triu(A)>0)% %% % Author: Bruno Luong <brunoluong@yahoo.com>% % Date: 21/March/2009% % if isscalar(sz)%     sz = [sz sz];% end% m=sz(1);% n=sz(2);% % % Main diagonal by default% if nargin<2%     k=0;% end% % nc = n-max(k,0); % number of columns of the triangular part% lo = ones(nc,1); % lower row indice for each column% hi = min((1:nc).'-min(k,0),m); % upper row indice for each column% % if isempty(lo)%     I = zeros(0,1);%     J = zeros(0,1);% else%     c=cumsum([0; hi-lo]+1); % cumsum of the length%     I = accumarray(c(1:end-1), (lo-[0; hi(1:end-1)]-1), ...%                    [c(end)-1 1]);%     I = cumsum(I+1); % row indice%     J = accumarray(c,1);%     J(1) = 1 + max(k,0); % The row indices starts from this value%     J = cumsum(J(1:end-1)); % column indice% end% % if nargout<2%     % convert to linear indices%     I = sub2ind([m n], I, J);% end% % end % itriu