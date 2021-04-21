CREATE TABLE cources(
    -- Можно использовать готовый тип для последовательности id
    -- id SERIAL PRIMARY KEY, 

    -- C 10й версии появился новый тип, который не создает новую сущность для последовательности
    -- Данный тип работает оптимальнее
    -- id INTEGER GENERATED AS IDENTITY,

    cource_no VARCHAR(30) PRIMARY KEY,
    title TEXT NOT NULL,
    credits INTEGER
);

CREATE TABLE students(
    stud_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    start_year INTEGER NOT NULL
);

CREATE TABLE exams(
    stud_id INTEGER REFERENCES students(stud_id),
    cource_no VARCHAR(30) REFERENCES cources(cource_no),
    exam_date DATE NULL,
    grade INTEGER NOT NULL,

    -- Будет использоваться составной первичный ключ
    PRIMARY KEY (stud_id, cource_no, exam_date)
);

INSERT INTO cources (cource_no, title, credits)
    VALUES ('CS301', 'Базы данных', 5),
           ('CS305', 'Анализ данных', 10);

INSERT INTO students (stud_id, name, start_year)
    VALUES (1451, 'Анна', 2014),
           (1432, 'Виктор', 2014),
           (1556, 'Нина', 2015);

INSERT INTO exams (stud_id, cource_no, exam_date, grade)
    VALUES (1451, 'CS301', '2016-05-25', 5),
           (1556, 'CS301', '2017-05-23', 5),
           (1451, 'CS305', '2016-05-25', 5),
           (1432, 'CS305', '2016-05-25', 4);

SELECT * FROM students;

-- На самом деле строка выше выглядит именно так, просто ALL опускается
SELECT ALL * FROM students;

-- DISTINCT позволяет выдергивать лишь уникальные значения
-- Но нужно использовать его без фанатизма, так как он снижает производительность
SELECT DISTINCT students.start_year FROM students;

-- Мы можем дергать данные из сразу нескольких таблиц
SELECT * 
    FROM cources, students, exams
    WHERE grade = 5
    ORDER BY name;

-- Так же мы можем джойнить данные при выборке сразу из нескольких таблиц
SELECT * 
    FROM cources, exams
    WHERE cources.cource_no = exams.cource_no;

-- Можно селектить значения из нескольких таблиц с помощью join
SELECT students.name, exams.grade, exams.cource_no
    FROM students
    JOIN exams ON exams.stud_id = students.stud_id 
    WHERE grade = 5
    ORDER BY name;

-- Можно выдернуть имя и курс студента для конкретного курса
-- при этом используя левую часть круга
-- Условие по ограничению курса специально идут в условиях Join,
-- таким образом фильтрация происходит на раннем этапе,
-- Если делать фильтрацию через WHERE, тогда будет фильтроватьс уже результат JOIN
SELECT students.name, exams.grade
    FROM students
    LEFT OUTER JOIN exams ON students.stud_id = exams.stud_id AND exams.cource_no = 'CS301';

-- Можно выдернуть имя и курс студента для конкретного курса
-- при этом используя пересечение значений, то есть не будет NULL
SELECT students.name, exams.grade
    FROM students
    INNER JOIN exams ON students.stud_id = exams.stud_id AND exams.cource_no = 'CS301';

-- Так же можно указывать псевдонимы для таблиц
SELECT s.name, e.grade AS ex_grade
    FROM students s
    INNER JOIN exams e ON s.stud_id = e.stud_id AND e.cource_no = 'CS301';

-- Данный пример подзапросов является не очень эффективным
-- так как мы селектимся в подзапросах сразу по нескольким полям
SELECT  (SELECT cources.cource_no FROM cources
            WHERE cources.cource_no  = exams.cource_no) AS cource_no,
        (SELECT cources.title 
            FROM cources
            WHERE cources.cource_no  = exams.cource_no) AS title,
        exams.exam_date,
        exams.stud_id,
        exams.grade
    FROM exams;

-- Мы можем так же использовать подзапросы в WHERE
SELECT stud_id, grade, cource_no
FROM exams
WHERE (SELECT start_year
       FROM students
       WHERE students.stud_id = exams.stud_id) > 2014;

-- Подзапросы так же могут быть использованы как список для фильтрации с помощью IN
SELECT name, start_year
FROM students
WHERE stud_id IN (SELECT stud_id FROM exams WHERE course_no = 'CS305');

-- Аналогично можно использовать и для фильтрации с NOT
SELECT name, start_year
FROM students
WHERE stud_id NOT IN (SELECT stud_id FROM exams WHERE grade < 5);

-- Подзапросы могут быть использованы для фильтрации
-- Если подзапрос возвращает NULL, тогда строка валидная
-- В подзапросе можно использовать значения из первичной таблицы
SELECT *
FROM students
WHERE NOT EXISTS (
    SELECT stud_id
    FROM exams
    WHERE grade < 5 AND exams.stud_id = students.stud_id
);

-- Получить всех студентов для которых существует экзамен,
-- у которого курс меньше 5го и id студента совпадает с экзаменом
SELECT *
FROM students
WHERE EXISTS (
     SELECT stud_id
     FROM exams
     WHERE grade < 5 AND exams.stud_id = students.stud_id
);

-- Можно делать упорядочивание сразу по нескольким полям
-- Приоритет упорядочивания будет по группам, указанным в списке
SELECT *
FROM exams
ORDER BY grade, stud_id, cource_no ASC;

-- Агрегирование позволяет собрать значения из всех полученных столбцов
-- DISTINCT - значит, что значения не повторяются, поэтому там значение будет меньше
SELECT count(*) AS total_count, count(DISTINCT stud_id) AS total_unique_students, avg(grade) AS avg_grade
FROM exams;

-- Агрегаторы хорошо работают с группам, группировка по сути часто нужна именно для них
SELECT cources.title, count(*), avg(exams.grade)
FROM exams
    JOIN cources ON exams.cource_no = cources.cource_no
GROUP BY cources.title;

-- count всегда возвращает хотя бы одну строку результата
SELECT count(*) FROM exams WHERE grade > 200;

-- Однако BROUP BY уже не выводит результаты
SELECT count(*) FROM exams WHERE grade > 200
GROUP BY cource_no;

-- Конструкция HAVING может быть использована для фильтрации значений после группировки
SELECT exams.stud_id
FROM exams
WHERE grade = 5
GROUP BY stud_id
HAVING count(*) > 1;

-- Мы можем выполнять получение результатов после выполнения операций обновления и вставки
UPDATE cources
SET credits = 12
WHERE cource_no = 'CS305'
RETURNING *;