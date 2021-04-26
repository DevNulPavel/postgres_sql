-- Можно использовать подзапросы, которые возвращают какое-то одно значение по условию
-- Так же можно указывать псевдонимы
-- Если подзапрос внезапно возвращает множество значений, тогда будет ошибка в рантайме
-- Если подзапрос не возвращает ни одного значения, тогда будет просто NULL в Postgres
SELECT  f.flight_no,
        f.departure_airport AS d_airport,
        (SELECT city
            FROM airports
            WHERE airport_code = f.departure_airport) AS dep_city,
        f.arrival_airport AS a_airport,
        (SELECT city
            FROM airports
            WHERE airport_code = f.arrival_airport) AS arr_city
    FROM flights f
    WHERE f.status = 'Departed' AND f.scheduled_arrival < bookings.now();

-- Вариант без подзапросов с выборкой сразу из нескольких таблиц, 
-- но объединением через WHERE + псевдонимы
SELECT f.flight_no,
       f.departure_airport AS d_airport,
       dep_a.city AS dep_city,
       f.arrival_airport AS a_airport,
       arr_a.city AS arr_city
    FROM flights f, airports dep_a, airports arr_a
    WHERE f.status = 'Departed' AND 
          f.scheduled_arrival < bookings.now() AND 
          f.departure_airport = dep_a.airport_code AND
          f.arrival_airport = arr_a.airport_code;

-- Тот же самый вариант с Join
SELECT f.flight_no,
       f.departure_airport AS d_airport,
       dep_a.city AS dep_city,
       f.arrival_airport AS a_airport,
       arr_a.city AS arr_city
    FROM flights f
    JOIN airports dep_a ON f.departure_airport = dep_a.airport_code
    JOIN airports arr_a ON f.arrival_airport = arr_a.airport_code
    WHERE f.status = 'Departed' AND 
          f.scheduled_arrival < bookings.now();

-- Можно использовать UNION для складывания значений
SELECT * FROM aircrafts WHERE range > 4500
UNION
SELECT * FROM aircrafts WHERE range < 7500;

-- Но более оптимальный вариант такой
SELECT * FROM aircrafts 
WHERE range > 4500 OR range < 7500;

-- Вариант с UNION ALL позволяет получить те же результаты, но при этом -
-- сохранить дубликаты значений
SELECT * FROM aircrafts WHERE range > 4500
UNION ALL
SELECT * FROM aircrafts WHERE range < 7500;

-- Так же мы можем использовать пересечение результатов
-- Это куда более полезная операция
SELECT * FROM aircrafts WHERE range > 4500
INTERSECT
SELECT * FROM aircrafts WHERE range < 7500;

-- Мы можем исключить из первого списка значения, которые
-- есть во втором списке
SELECT * FROM aircrafts WHERE range > 4500
EXCEPT
SELECT * FROM aircrafts WHERE range < 7500;

-- Мы можем вручную создавать последовательности
CREATE SEQUENCE my_seq;

-- Получать новое значение из последовательности можно следующим образом
SELECT nextval('my_seq');

-- Так же можно просто получать текущее значение последовательности
SELECT currval('my_seq');

-- Можно создавать представления, которые будут из себя представлять некие виртуальные таблицы
-- Что интересно, можно переопределять тип данных с помощью ::
-- Из типа TIMESTAMP можно сделать DATE
CREATE VIEW upcoming_flights AS
    SELECT f.flight_id,
           f.flight_no,
           f.scheduled_departure::date AS d_date,
           dep.airport_code AS d_airport,
           arr.airport_code AS a_airport
    FROM flights f
        JOIN airports dep ON dep.airport_code = f.departure_airport
        JOIN airports arr ON arr.airport_code = f.arrival_airport
    WHERE f.scheduled_departure BETWEEN bookings.now()
      AND bookings.now() + INTERVAL '7 days';

-- Затем можно использовать представления как обычные таблицы
-- Но надо понимать, что view могут быть не очень производительны
-- если выборка будет происходить только по простым значениям из одной таблицы
-- тогда проще использовать просто обычный запрос
SELECT * FROM upcoming_flights
WHERE a_airport = 'DYR';

-- Создаем индекс по именам пассажиров
CREATE INDEX tickets_passenger_name_idx
ON tickets(passenger_name);

-- Создаем вью для вытягивания информации шереметьево
CREATE VIEW svo_led_utilization AS
    SELECT f.flight_no,
           f.scheduled_departure,
           count(tf.ticket_no) AS passengers
    FROM flights f
    JOIN ticket_flights tf 
        ON tf.flight_id = f.flight_id
    WHERE f.departure_airport = 'SVO' 
        AND f.arrival_airport = 'LED' 
        AND f.scheduled_departure BETWEEN bookings.now() - INTERVAL '1 day' AND bookings.now()
    GROUP BY f.flight_no, f.scheduled_departure;

-- Если сделать сейчас выборку, то она будет долгой, так как нету индекса
SELECT * FROM svo_led_utilization;

-- Можно дополнительно получить информацию по селекту данных
EXPLAIN (costs off)
SELECT * FROM svo_led_utilization;

-- Теперь можно создать индекс по аэропортам отправки + по индексам билетов
CREATE INDEX flights_departure_airport_idx
    ON flights(departure_airport);
CREATE INDEX flights_arrival_airport_idx
    ON flights(arrival_airport);
CREATE INDEX ticket_flights_flight_id_idx
    ON ticket_flights(flight_id);

-- Теперь видно, что здесь уже происходит вытягивание данных быстро из индекса
EXPLAIN (costs off)
SELECT * FROM svo_led_utilization;

-- Тут данные вытягиваются быстро
SELECT * FROM svo_led_utilization;

-- Получаем все модели самолетов, которые у нас есть
SELECT * FROM aircrafts;

-- Модели самолетов с диапазоном больше 10000 или меньше 4000
SELECT * FROM aircrafts WHERE range > 10000 OR range < 4000;

-- Все модели самолетов с диапазоном больше 2000 и именем, заканчивающимся на 100
SELECT * FROM aircrafts WHERE range >= 2000 AND model LIKE '%100';

-- Определить номера и время отправления всех рейсов, 
-- прибывших в аэропорт назначения не во время
SELECT * FROM flights WHERE scheduled_departure != actual_departure LIMIT 10;

-- Получаем возможные статусы полетов
SELECT DISTINCT status FROM flights;

-- Подсчитайте количество отмененных рейсов из аэропорта Пулково (LED), 
-- как вылет, так и прибытие которых было назначено на четверг.
SELECT count(flight_id) FROM flights 
WHERE departure_airport = 'VKO' 
    AND status = 'Cancelled'
    AND date_part('dow', scheduled_departure) = 4
    AND date_part('dow', scheduled_arrival) = 4;

-- Типы бронирований
SELECT DISTINCT fare_conditions FROM ticket_flights;

-- Выведите имена пассажиров, купивших билеты эконом-
-- класса за сумму, превышающую 70 000 рублей.
SELECT passenger_name, ticket_flights.amount
FROM tickets 
INNER JOIN ticket_flights ON tickets.ticket_no = ticket_flights.ticket_no
WHERE ticket_flights.fare_conditions = 'Economy' 
    AND ticket_flights.amount > 70000
ORDER BY ticket_flights.amount DESC;

-- Выведите имена пассажиров, купивших СУММАРНО билетов эконом-
-- класса за сумму, превышающую 70 000 рублей.
SELECT passenger_name, SUM(ticket_flights.amount) AS total_amount 
FROM tickets 
INNER JOIN ticket_flights ON tickets.ticket_no = ticket_flights.ticket_no
WHERE ticket_flights.fare_conditions = 'Economy' 
GROUP BY passenger_name
HAVING SUM(ticket_flights.amount) > 70000
ORDER BY total_amount DESC
LIMIT 10;

-- Напечатанный посадочный талон должен содержать фамилию и имя пассажира, 
-- коды аэропортов вылета и прилета, 
-- дату и время вылета и прилета по расписанию, 
-- номер места в салоне самолета. 
-- Напишите запрос, выводящий всю необходимую информацию для полученных посадочных талонов на рейсы, 
-- которые еще не вылетели.
SELECT * 
FROM boarding_passes
INNER JOIN ticket_flights ON ticket_flights.ticket_no = boarding_passes.ticket_no
INNER JOIN flights ON flights.flight_id = boarding_passes.flight_id
WHERE flights.status = 'Scheduled' 
    OR flights.status = 'Delayed'
    OR flights.status = 'On Time'
LIMIT 10;

-- Некоторые пассажиры, вылетающие сегодняшним рейсом («сегодня» определяется функцией bookings.now), 
-- еще не прошли регистрацию, 
-- т. е. не получили посадочного талона. 
-- Выведите имена этих пассажиров и номера рейсов.
SELECT tickets.passenger_name, flights.flight_no
FROM ticket_flights
INNER JOIN tickets ON tickets.ticket_no = ticket_flights.ticket_no
INNER JOIN flights ON flights.flight_id = ticket_flights.flight_id
LEFT JOIN boarding_passes ON boarding_passes.ticket_no = ticket_flights.ticket_no
WHERE boarding_passes.ticket_no IS NULL
    AND flights.scheduled_departure 
        BETWEEN bookings.now()
        AND bookings.now() + INTERVAL '1 days'
LIMIT 10;

-- Выведите номера мест, оставшихся свободными в рейсах из Анапы (AAQ) в Шереметьево (SVO), 
-- вместе с номером рейса и его датой.
SELECT seats.seat_no, flights.flight_no, flights.scheduled_departure
FROM seats
INNER JOIN aircrafts ON aircrafts.aircraft_code = seats.aircraft_code
INNER JOIN flights ON flights.aircraft_code = aircrafts.aircraft_code
LEFT JOIN boarding_passes ON boarding_passes.seat_no = seats.seat_no
WHERE flights.departure_airport = 'AAQ' 
    AND flights.arrival_airport = 'SVO'
    AND flights.scheduled_departure 
        BETWEEN bookings.now()
        AND bookings.now() - INTERVAL '1 days'
    AND boarding_passes.ticket_no IS NULL;

-- Напишите запрос, возвращающий среднюю стоимость авиабилета из Воронежа (VOZ) в Санкт-Петербург (LED). 
-- Поэкспериментируйте с другими агрегирующими функциями (sum, max). 
-- Какие еще агрегирующие функции бывают?
SELECT AVG(amount)
FROM ticket_flights 
INNER JOIN flights
    ON flights.flight_id = ticket_flights.flight_id
WHERE
    flights.departure_airport = 'VOZ' 
    AND flights.arrival_airport = 'LED';

-- Напишите запрос, возвращающий среднюю стоимость авиабилета в каждом из классов перевозки. 
-- Модифицируйте его таким образом, чтобы было видно, какому классу какое значение соответствует.
SELECT fare_conditions, AVG(amount)
FROM ticket_flights
GROUP BY fare_conditions;

-- Выведите все модели самолетов вместе с общим количеством мест в салоне.
SELECT aircrafts.model, COUNT(seats.seat_no)
FROM aircrafts
INNER JOIN seats ON seats.aircraft_code = aircrafts.aircraft_code
GROUP BY aircrafts.model;

-- Напишите запрос, возвращающий список аэропортов, в которых было принято более 500 рейсов.
SELECT airports.airport_name, COUNT(flights.flight_id) AS count
FROM airports
INNER JOIN flights on airports.airport_code = flights.arrival_airport
GROUP BY airports.airport_name
HAVING COUNT(flights.flight_id) > 500
ORDER BY count ASC;

-- Авиакомпания провела модернизацию салонов всех имеющихся самолетов «Сессна» (код CN1), 
-- в результате которой был добавлен седьмой ряд кресел. 
-- Измените соответствующую таблицу, чтобы отразить этот факт.
INSERT INTO seats (aircraft_code, seat_no, fare_conditions) 
VALUES  ('CN1', '7A', 'Economy'),
        ('CN1', '7B', 'Economy');

-- В результате еще одной модернизации в самолетах «Аэробус A319» (код 319) 
-- ряды кресел с шестого по восьмой были переведены в разряд бизнес-класса. 
-- Измените таблицу одним запросом и получите изме- ненные данные с помощью предложения RETURNING.
UPDATE seats 
SET fare_conditions = 'Business' 
WHERE aircraft_code = '319' 
    AND (seat_no LIKE '6%' 
         OR seat_no LIKE '7%' 
         OR seat_no LIKE '8%') 
RETURNING *;

-- Создайте новое бронирование текущей датой. В качестве номера 
--      бронирования можно взять любую последовательность из шести символов, 
--      начинающуюся на символ подчеркивания. Общая сумма должна составлять 30 000 рублей.
-- Создайте электронный билет, связанный с бронированием, на ваше имя.
-- Назначьте электронному билету два рейса: один из Москвы (VKO) во Владивосток (VVO) через неделю, 
--      другой — обратно через две недели. 
-- Оба рейса выполняются эконом-классом, стоимость каждого должна состав- лять 15 000 рублей.
BEGIN;
    INSERT INTO bookings (book_ref, book_date, total_amount)
        VALUES ('_qwert', now(), 30000) 
        RETURNING *;
    SAVEPOINT booking_svp;
    -- ROLLBACK TO SAVEPOINT booking_svp;
    
    INSERT INTO tickets (ticket_no, book_ref, passenger_id, passenger_name, contact_data)
        VALUES ('qweqweqwefdsf', '_qwert', 'test_passenger_id', 'PAVEL ERSHOV', '{"phone": "+70125366530"}')
        RETURNING *;
    SAVEPOINT tickets_svp;
    -- ROLLBACK TO SAVEPOINT tickets_svp;

    INSERT INTO ticket_flights (ticket_no, flight_id, fare_conditions, amount)
        VALUES ('qweqweqwefdsf', 
                (SELECT flight_id 
                    FROM flights 
                    WHERE departure_airport = 'VKO' 
                        AND arrival_airport = 'VVO'
                        AND scheduled_departure > bookings.now() + INTERVAL '1 week'
                    LIMIT 1), 
                'Economy', 
                15000),
                ('qweqweqwefdsf', 
                (SELECT flight_id 
                    FROM flights 
                    WHERE departure_airport = 'VVO' 
                        AND arrival_airport = 'VKO'
                        AND scheduled_departure > bookings.now() + INTERVAL '2 week'
                    LIMIT 1), 
                'Economy', 
                15000);
    SAVEPOINT ticket_flights_svp;
    -- ROLLBACK TO SAVEPOINT ticket_flights_svp;
COMMIT;

