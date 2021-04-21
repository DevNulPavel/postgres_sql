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