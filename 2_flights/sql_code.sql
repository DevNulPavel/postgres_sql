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

-- Авиакомпания хочет предоставить пассажирам возможность повышения класса обслуживания уже после 
-- покупки билета при регистрации на рейс. 
-- За это взимается отдельная плата. 
-- Добавьте в демонстрационную базу данных возможность хранения таких операций.
BEGIN;
    --  Создаем таблицу
    -- TODO: Вынести проверку в общую функцию
    CREATE TABLE fare_changes_price (
        previous_fare VARCHAR(10) NOT NULL CHECK prev_check (previous_fare IN ('Economy', 'Comfort', 'Business')),
        new_fare VARCHAR(10) NOT NULL CHECK new_check (previous_fare IN ('Economy', 'Comfort', 'Business')),
        price INTEGER NOT NULL CHECK price_check (price > 0)
    );
    SAVEPOINT table_created;
    -- ROLLBACK TO SAVEPOINT table_created;

    -- ALTER TABLE fare_changes_price
    --     DROP CONSTRAINT new_check;

    -- ALTER TABLE fare_changes_price
    --     ADD CONSTRAINT new_check CHECK (new_fare IN ('Economy', 'Comfort', 'Business'));

    -- Добавляем значения
    INSERT INTO fare_changes_price(previous_fare, new_fare, price)
        VALUES ('Economy', 'Comfort', 2000),
               ('Economy', 'Business', 3000),
               ('Comfort', 'Business', 4000);
COMMIT;

-- Авиакомпания начинает выдавать пассажирам карточки постоянных клиентов. 
-- Вместо того чтобы каждый раз вводить имя, номер документа и контактную информацию, постоянный клиент может указать 
-- номер своей карты, к которой привязана вся необходимая информация. 
-- При этом клиенту может предоставляться скидка.
-- Измените существующую схему данных так, чтобы иметь возможность хранить информацию о постоянных клиентах.
BEGIN;
    CREATE TABLE user_carts (
        user_cart_id SERIAL PRIMARY KEY,
        user_name VARCHAR(30) NOT NULL,
        email VARCHAR(30) NOT NULL,
        discout_percent INTEGER NOT NULL,

        CONSTRAINT discount_check CHECK (discout_percent > 0)
    );
    SAVEPOINT table_created;
    -- ROLLBACK TO SAVEPOINT table_created;    

    ALTER TABLE tickets 
        ADD COLUMN user_cart_id INTEGER 
        CONSTRAINT cart_id_constr REFERENCES user_carts(user_cart_id);
COMMIT;


-- Постоянные клиенты могут бесплатно провозить с собой животных. 
-- Добавьте в ранее созданную таблицу постоянных клиентов информацию о перевозке домашних животных.
BEGIN;
    ALTER TABLE user_carts
        ADD COLUMN with_free_animals BOOL NOT NULL DEFAULT false;
COMMIT;


-- Найдите модели самолетов «дальнего следования», максимальная продолжительность 
-- рейсов которых составила более 6 часов.
SELECT DISTINCT model
    FROM aircrafts
    WHERE aircraft_code IN (
        SELECT DISTINCT aircraft_code 
            FROM flights 
            WHERE (actual_arrival - actual_departure) > INTERVAL '6 hours'
    );
-- То же самое но без подзапроса
SELECT DISTINCT model 
    FROM flights 
    INNER JOIN aircrafts ON aircrafts.aircraft_code = flights.aircraft_code
    WHERE (actual_arrival - actual_departure) > INTERVAL '6 hours';


-- Подсчитайте количество рейсов, которые хотя бы раз были задержаны более чем на 4 часа.
SELECT COUNT(flight_id) AS count
    FROM (
        SELECT flight_id 
            FROM flights
            WHERE (actual_departure - scheduled_departure) > INTERVAL '4 hours'
    ) AS failed_flights;

-- То же самое без подзапроса
-- SELECT COUNT(flight_id) AS count
--     FROM flights
--     WHERE (actual_departure - scheduled_departure) > INTERVAL '4 hours';

-- SELECT arrival_airport, departure_airport, COUNT(flight_id) AS count
--     FROM flights
--     WHERE (actual_departure - scheduled_departure) > INTERVAL '4 hours'
--     GROUP BY arrival_airport, departure_airport
--     HAVING COUNT(flight_id) > 10;


-- Для составления рейтинга аэропортов учитывается суточная пропускная способность, 
--      т. е. среднее количество вылетевших из него и прилетевших в него за сутки пассажиров. 
-- Выведите 10 аэропортов с наибольшей суточной пропускной способностью, упорядоченных по убыванию данной величины.
-- Количество вылетов по месяцам
SELECT date_trunc('month', actual_departure), COUNT(flights.flight_id)
    FROM flights
    WHERE actual_departure IS NOT NULL
    GROUP BY 1;
-- Количество прилетов по месяцам
SELECT date_trunc('month', actual_arrival), COUNT(flights.flight_id)
    FROM flights
    WHERE actual_arrival IS NOT NULL
    GROUP BY 1;
-- Количество билетов вылета по дням на конкретный аэропорт
SELECT arrival_airport, date_trunc('day', actual_departure), COUNT(ticket_flights.ticket_no)
    FROM ticket_flights
    INNER JOIN flights ON flights.flight_id = ticket_flights.flight_id
    WHERE actual_arrival IS NOT NULL
    GROUP BY 1,2;
-- Среднее количество билетов прилета в день для аэропорта
SELECT arrival_airport, AVG(tickets_count) as arr_average
    FROM (
        SELECT  arrival_airport, 
                date_trunc('day', actual_departure) AS dep_day, 
                COUNT(ticket_flights.ticket_no) AS tickets_count
            FROM ticket_flights
            INNER JOIN flights ON flights.flight_id = ticket_flights.flight_id
            WHERE actual_arrival IS NOT NULL
            GROUP BY 1,2
    ) AS count_by_day
    GROUP BY arrival_airport;
-- Среднее количество билетов вылета в день для аэропорта
SELECT departure_airport, AVG(tickets_count) as dep_average
    FROM (
        SELECT  departure_airport, 
                date_trunc('day', actual_departure) AS dep_day, 
                COUNT(ticket_flights.ticket_no) AS tickets_count
            FROM ticket_flights
            INNER JOIN flights ON flights.flight_id = ticket_flights.flight_id
            WHERE actual_departure IS NOT NULL
            GROUP BY 1,2
    ) AS count_by_day
    GROUP BY departure_airport;
-- Результирующий запрос
SELECT airport, SUM(average)
    FROM (
        SELECT arrival_airport AS airport, AVG(tickets_count) as average
            FROM (
                SELECT  arrival_airport, 
                        date_trunc('day', actual_departure) AS dep_day, 
                        COUNT(ticket_flights.ticket_no) AS tickets_count
                    FROM ticket_flights
                    INNER JOIN flights ON flights.flight_id = ticket_flights.flight_id
                    WHERE actual_arrival IS NOT NULL
                    GROUP BY 1,2
            ) AS count_by_day
            GROUP BY arrival_airport
        UNION 
            SELECT departure_airport AS airport, AVG(tickets_count) as average
            FROM (
                SELECT  departure_airport, 
                        date_trunc('day', actual_departure) AS dep_day, 
                        COUNT(ticket_flights.ticket_no) AS tickets_count
                    FROM ticket_flights
                    INNER JOIN flights ON flights.flight_id = ticket_flights.flight_id
                    WHERE actual_departure IS NOT NULL
                    GROUP BY 1,2
                ) AS count_by_day
                GROUP BY departure_airport
    ) AS sub_table
    GROUP BY 1
    ORDER BY 2 DESC
    LIMIT 10;

-- С целью оценки интенсивности работы обслуживающего персонала аэропорта Шереметьево (SVO) вычислите, 
-- сколько раз вылеты следовали друг за другом с перерывом менее пяти минут.
SELECT COUNT(f1.flight_id)
    FROM flights AS f1, flights AS f2
    WHERE f1.departure_airport = 'SVO'
        AND f2.departure_airport = 'SVO'
        AND f1.actual_departure > f2.actual_departure
        AND (f1.actual_departure - f2.actual_departure) < INTERVAL '5 min';


-- Количество рейсов, принятых конкретным аэропортом за каждый день — довольно востребованный запрос. 
-- Напишите представление данного запроса для аэропорта города Барнаул (BAX).
CREATE VIEW bax_arrived_count AS
    SELECT date_trunc('day', actual_arrival)::DATE AS date, COUNT(*)
        FROM flights
        WHERE arrival_airport = 'BAX' AND actual_arrival IS NOT NULL
        GROUP BY date_trunc('day', actual_arrival)
        ORDER BY date;
SELECT * FROM bax_arrived_count;

-- Создание нового пользоваеля
CREATE ROLE reader;
-- Либо
CREATE USER reader;

-- Получить его состояние 
\du reader;

-- Позволить пользователю логиниться
ALTER USER reader LOGIN;

-- Можем дать права на чтение данных из определенной таблицы пользователю
GRANT SELECT ON TABLE airports TO reader;

-- Отменить можно так
REVOKE SELECT ON TABLE airports FROM reader;

-- Можем дать возможность читать из всех таблиц сразу
GRANT SELECT ON ALL TABLES IN SCHEMA bookings TO reader;

-- Можно скопировать права от одного пользователя к другому
GRANT reader TO writer;

-- Уровень изоляции транзакций можно сделать выше
BEGIN;
    -- SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    -- SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    -- SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
COMMIT;

----------------------------------------------------------------------------------------

-- Перед началом выполнения задания проверьте, что в таблице 
-- bookings нет бронирований на сумму total_amount 1 000 рублей.
-- 1. В первом сеансе начните транзакцию (командой BEGIN). 
--      Выполните обновление таблицы bookings: увеличьте total_amount в два раза в тех строках, где сумма равна 1 000 рублей.
-- 2. Во втором сеансе(откройте новое окно psql) вставьте в таблицу bookings новое бронирование на 1 000 рублей и 
--      зафиксируйте транзакцию.
-- 3. В первом сеансе повторите обновление таблицы bookings и зафиксируйте транзакцию.
-- Осталась ли сумма добавленного бронирования равной 1 000 рублей? Почему это не так?
SELECT * FROM bookings WHERE total_amount = 1000;
-- 1
BEGIN;
    -- Данный режим транзакции значит, что в процессе транзации 
    -- если другая транзакция закоммитит новое значение
    -- то в текущей транзакции мы сможем прочитать эти данные
    -- То есть нету полной атомарности при чтении
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    
    UPDATE bookings 
        SET total_amount = total_amount*2 
        WHERE total_amount = 1000
        RETURNING *;

    UPDATE bookings 
        SET total_amount = total_amount*2 
        WHERE total_amount = 1000
        RETURNING *;
COMMIT;
-- 2
BEGIN;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    
    INSERT INTO bookings (book_ref, book_date, total_amount)
        VALUES ('ASDASD', '2021-04-29 06:02:00+00', 1000)
        RETURNING *;
COMMIT;
-- 3
DELETE FROM bookings 
    WHERE total_amount = 2000
    RETURNING *;

----------------------------------------------------------------------------------------

-- Повторите предыдущее упражнение, но начните транзакцию в первом сеансе с 
-- уровнем изоляции транзакций Repeatable Read. Объясните различие полученных результатов.
SELECT * FROM bookings WHERE total_amount = 1000;
-- 1
BEGIN;
    -- Данный режим транзакции значит, что при чтении данных мы не будем учитывать измененные где-то еще
    -- данные при очередном чтении
    -- Как результат - оба вызова не изменят состояние цены
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
    UPDATE bookings 
        SET total_amount = total_amount*2 
        WHERE total_amount = 1000
        RETURNING *;

    UPDATE bookings 
        SET total_amount = total_amount*2 
        WHERE total_amount = 1000
        RETURNING *;
COMMIT;
-- 2
BEGIN;
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
    INSERT INTO bookings (book_ref, book_date, total_amount)
        VALUES ('ASDASD', '2021-04-29 06:02:00+00', 1000)
        RETURNING *;
COMMIT;
-- 3
DELETE FROM bookings 
    WHERE book_ref = 'ASDASD'
    RETURNING *;

----------------------------------------------------------------------------------------
-- Выполните указанные действия в двух сеансах:
-- 1. В первом сеансе начните новую транзакцию с уровнем изоляции Repeatable Read. 
--      Вычислите количество бронирований с суммой 20 000 рублей.
-- 2. Во втором сеансе начните новую транзакцию с уровнем изоляции Repeatable Read. 
--      Вычислите количество бронирований с суммой 30 000 рублей.
-- 3. В первом сеансе добавьте новое бронирование на 30000 рублей и снова 
--      вычислите количество бронирований с суммой 20 000 рублей.
-- 4. Во втором сеансе добавьте новоебронирование на 20000 рублей и снова вычислите количество бронирований 
--      с суммой 30 000 рублей.
-- 5. Зафиксируйте транзакции в обоих сеансах.
-- Соответствует ли результат ожиданиями? 
-- Можно ли сериализовать эти транзакции (иными словами, можно ли представить такой порядок последовательного 
--      выполнения этих транзакций, при котором результат совпадет с тем, что получился при параллельном выполнении)?