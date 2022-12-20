clc;
clear all;
close all;

expcdf_2 = @(vec, mu) expcdf(vec * ((mu * 9.9035) / length(vec)), mu);

customer_num = input('Enter the number of customers in the system (must be a positive number): '); % The number of customers in the system
lambda = input('Enter λ - the average time of arrivals per time period(must be a positive number and smaller than 𝜇): ');
mu = input('Enter 𝜇 - the average number of people served per time period(must be a positive number and greater than λ): ');

max_interarrival_time = input('Enter the maximum interarrival time: ');
expected_time_bet_arrival = 1:max_interarrival_time;
probability_distribution_arrival_time = expcdf_2(expected_time_bet_arrival, lambda);

max_service_time = input('Enter the maximum service time: ');
service_time = 1 : max_service_time;
probability_distribution_service_time = expcdf_2(service_time, mu);

% Bar chart for the commulative probabilities
figure
bar(round(probability_distribution_arrival_time, 4));
title('Arrival time commulative probability distribution')
figure
bar(round(probability_distribution_service_time, 4));
title('Service time commulative probability distribution')

random_dig_arrival_time = round(probability_distribution_arrival_time, 4) * 10000; % Mutiplied by 1000 to be then compared with the generated random numbers
random_dig_service_time = round(probability_distribution_service_time, 4) * 10000; % Mutiplied by 100 to be then compared with the generated random numbers

rt = randi([1 10000], 1, customer_num); %random digit assignment for the interarrival time
rs = randi([1 10000], 1, customer_num); %random digit assignment for the service time

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cus_interarival_time = zeros(1, customer_num); % vector of size 1x20 to hold the interaarrival times for each customer

for i = 2:customer_num
  for j = 1:length(random_dig_arrival_time)
    if rt(i) <= random_dig_arrival_time(j)
      cus_interarival_time(i) = expected_time_bet_arrival(j); %1:8
      break;
    end
  end
end

cus_arrival_time = cumsum(cus_interarival_time); % from the starting of the system 0 8 10 18 etc..
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cus_service_time = zeros(1, customer_num);

for i = 1:customer_num
  for j = 1:length (random_dig_service_time)
    if rs(i) <= random_dig_service_time(j)
      cus_service_time(i) = service_time(j);
      break;
    end
  end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Adding extra service time due to random event outside of the system (Coffee break)
for i = 1:customer_num
    if randi(2) - 1 > 0
        cus_service_time(i) = cus_service_time(i) + randi(2);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Simulation

no_of_servers = input('Enter the number of servers (Must be greater than zero): ');

time = 0;
queue = [];
q_length = [];
Servers_busy = zeros(1, no_of_servers);
time_service_ends = zeros(1, no_of_servers);

cus_number = 0;
sim_time = cus_arrival_time(end); % that is why we accumilated all the interarrival times for all the customers to determine the true simulation time of our queue
waiting_time = cus_arrival_time;

% disp(['The expected simulation time for the whole queue and service processes = ' num2str(sim_time)]); %The expected simulation time for the whole queue and service processes

while (time <= sim_time || ~isempty(queue) || ismember(1, Servers_busy))

  if (ismember(time, cus_arrival_time)) % time is equal customer arrival time
    cus_number = cus_number + 1; % indicate that this is the next customer
    queue = [cus_number queue]; % add new customer to queue
  end

  if (ismember(0, Servers_busy) && ~isempty(queue)) %Server is idle and queue is not empty
    free = find(~Servers_busy);

    while (~isempty(free) && ~isempty(queue))
      Servers_busy(free(end)) = 1; % make service busy
      waiting_time(queue(end)) = time - waiting_time(queue(end));
      time_service_ends(free(end)) = time + cus_service_time(queue(end)); % time the service ends = current time + customer service time that is assigned to the last customer in the queue
      queue = queue(:, 1:end - 1); % remove one from queue
      free = free(:, 1:end - 1); % remove one from queue
    end

  end

  if (ismember(time, time_service_ends)) % time is equal to the time the service ends
    done = find(time_service_ends == time);
    Servers_busy(done) = 0;
  end

  q_length = [q_length length(queue)];
  time = time + 1; % increment time
end

sim_time = time - 1; % Total simulation time
system_time = waiting_time + cus_service_time;

if no_of_servers == 1
  utilization = @(lambda, mu) lambda / mu;
  L = @(lambda, mu) lambda / (mu - lambda);
  W = @(lambda, mu) 1 / (mu - lambda);
  Lq = @(lambda, mu) lambda ^ 2 / (mu * (mu - lambda));
  Wq = @(lambda, mu) lambda / (mu * (mu - lambda));
else
  utilization = @(lambda, mu) lambda / (mu * no_of_servers);
  syms n;
  P0 = 1 / (symsum((1 / factorial(n)) * ((lambda / mu) ^ n), n, 0, no_of_servers - 1) + (1 / factorial(no_of_servers)) * ((lambda / mu) ^ no_of_servers) * ((no_of_servers * mu) / ((no_of_servers * mu) - lambda)));
  L = @(lambda, mu) (((lambda * mu * ((lambda / mu) ^ no_of_servers)) / (factorial(no_of_servers - 1) * (no_of_servers * mu - lambda) ^ 2)) * P0) + (lambda / mu);
  W = @(lambda, mu) (((mu * ((lambda / mu) ^ no_of_servers)) / (factorial(no_of_servers - 1) * (no_of_servers * mu - lambda) ^ 2)) * P0) + (1 / mu);
  Lq = @(lambda, mu) L(lambda, mu) - (lambda / mu);
  Wq = @(lambda, mu) W(lambda, mu) - (1 / mu);
end

% Bar chart shows the number of customers waiting in the queue
figure
ttt = 0:sim_time;
bar(ttt, q_length);
title('Number of customers waiting in the queue at each time');
xlabel('Time');
ylabel('Number of customers');

disp([' ']);
disp(['The simulation time for the whole queue and service processes = ' num2str(sim_time) ' Customer']);
disp(['Average waiting time in the queue = ' num2str(mean(waiting_time)) ' Time units']);
disp(['Average time the customers spend in the system = ' num2str(mean(system_time)) ' Time units']);
disp([' ']);
disp(['ρ (Utilization)= ' num2str(utilization(lambda, mu) * 100) '%']);
disp(['L (Average number of customers in the system)= ' num2str(double(L(lambda, mu))) ' Customer']);
disp(['W (Average time a customer spends in the system)= ' num2str(double(W(lambda, mu))) ' Time units']);
disp(['Lq (Average number of customers waiting in the queue)= ' num2str(double(Lq(lambda, mu))) ' Customer']);
disp(['Wq (Average time a customer spends waiting in the queue)= ' num2str(double(Wq(lambda, mu))) ' Time units']);