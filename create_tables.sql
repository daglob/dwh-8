CREATE SCHEMA bookings_dwh;

/*
Fact_Flights - содержит совершенные перелеты. Если в рамках билета был сложный маршрут с пересадками - каждый сегмент учитываем независимо
    Пассажир
    Дата и время вылета (факт)
    Дата и время прилета (факт)
    Задержка вылета (разница между фактической и запланированной датой в секундах)
    Задержка прилета (разница между фактической и запланированной датой в секундах)
    Самолет
    Аэропорт вылета
    Аэропорт прилета
    Класс обслуживания
    Стоимость

Dim_Calendar - справочник дат
Dim_Passengers - справочник пассажиров
Dim_Aircrafts - справочник самолетов
Dim_Airports - справочник аэропортов
Dim_Tariff - справочник тарифов (Эконом/бизнес и тд)
*/
-- DROP TABLE if exists  bookings_dwh.Dim_Calendar CASCADE;
CREATE TABLE bookings_dwh.Dim_Calendar
(
    id                     INT         NOT NULL,
    date_actual            DATE        NOT NULL,
    epoch                  BIGINT      NOT NULL,
    day_suffix             VARCHAR(4)  NOT NULL,
    day_name               VARCHAR(15) NOT NULL,
    day_of_week            INT         NOT NULL,
    day_of_month           INT         NOT NULL,
    day_of_quarter         INT         NOT NULL,
    day_of_year            INT         NOT NULL,
    week_of_month          INT         NOT NULL,
    week_of_year           INT         NOT NULL,
    week_of_year_iso       CHAR(10)    NOT NULL,
    month_actual           INT         NOT NULL,
    month_name             VARCHAR(9)  NOT NULL,
    month_name_abbreviated CHAR(3)     NOT NULL,
    quarter_actual         INT         NOT NULL,
    quarter_name           VARCHAR(9)  NOT NULL,
    year_actual            INT         NOT NULL,
    first_day_of_week      DATE        NOT NULL,
    last_day_of_week       DATE        NOT NULL,
    first_day_of_month     DATE        NOT NULL,
    last_day_of_month      DATE        NOT NULL,
    first_day_of_quarter   DATE        NOT NULL,
    last_day_of_quarter    DATE        NOT NULL,
    first_day_of_year      DATE        NOT NULL,
    last_day_of_year       DATE        NOT NULL,
    mmyyyy                 CHAR(6)     NOT NULL,
    mmddyyyy               CHAR(10)    NOT NULL,
    weekend_indr           BOOLEAN     NOT NULL
);

ALTER TABLE bookings_dwh.Dim_Calendar
    ADD CONSTRAINT d_date_date_dim_id_pk PRIMARY KEY (id);

CREATE INDEX d_date_date_actual_idx
    ON bookings_dwh.Dim_Calendar (date_actual);

COMMIT;

INSERT INTO bookings_dwh.Dim_Calendar
SELECT TO_CHAR(datum, 'yyyymmdd')::INT                                                        AS id,
       datum                                                                                  AS date_actual,
       EXTRACT(EPOCH FROM datum)                                                              AS epoch,
       TO_CHAR(datum, 'fmDDth')                                                               AS day_suffix,
       TO_CHAR(datum, 'TMDay')                                                                AS day_name,
       EXTRACT(ISODOW FROM datum)                                                             AS day_of_week,
       EXTRACT(DAY FROM datum)                                                                AS day_of_month,
       datum - DATE_TRUNC('quarter', datum)::DATE + 1                                         AS day_of_quarter,
       EXTRACT(DOY FROM datum)                                                                AS day_of_year,
       TO_CHAR(datum, 'W')::INT                                                               AS week_of_month,
       EXTRACT(WEEK FROM datum)                                                               AS week_of_year,
       EXTRACT(ISOYEAR FROM datum) || TO_CHAR(datum, '"-W"IW-') || EXTRACT(ISODOW FROM datum) AS week_of_year_iso,
       EXTRACT(MONTH FROM datum)                                                              AS month_actual,
       TO_CHAR(datum, 'TMMonth')                                                              AS month_name,
       TO_CHAR(datum, 'Mon')                                                                  AS month_name_abbreviated,
       EXTRACT(QUARTER FROM datum)                                                            AS quarter_actual,
       CASE
           WHEN EXTRACT(QUARTER FROM datum) = 1 THEN 'First'
           WHEN EXTRACT(QUARTER FROM datum) = 2 THEN 'Second'
           WHEN EXTRACT(QUARTER FROM datum) = 3 THEN 'Third'
           WHEN EXTRACT(QUARTER FROM datum) = 4 THEN 'Fourth'
           END                                                                                AS quarter_name,
       EXTRACT(YEAR FROM datum)                                                               AS year_actual,
       datum + (1 - EXTRACT(ISODOW FROM datum))::INT                                          AS first_day_of_week,
       datum + (7 - EXTRACT(ISODOW FROM datum))::INT                                          AS last_day_of_week,
       datum + (1 - EXTRACT(DAY FROM datum))::INT                                             AS first_day_of_month,
       (DATE_TRUNC('MONTH', datum) + INTERVAL '1 MONTH - 1 day')::DATE                        AS last_day_of_month,
       DATE_TRUNC('quarter', datum)::DATE                                                     AS first_day_of_quarter,
       (DATE_TRUNC('quarter', datum) + INTERVAL '3 MONTH - 1 day')::DATE                      AS last_day_of_quarter,
       TO_DATE(EXTRACT(YEAR FROM datum) || '-01-01', 'YYYY-MM-DD')                            AS first_day_of_year,
       TO_DATE(EXTRACT(YEAR FROM datum) || '-12-31', 'YYYY-MM-DD')                            AS last_day_of_year,
       TO_CHAR(datum, 'mmyyyy')                                                               AS mmyyyy,
       TO_CHAR(datum, 'mmddyyyy')                                                             AS mmddyyyy,
       CASE
           WHEN EXTRACT(ISODOW FROM datum) IN (6, 7) THEN TRUE
           ELSE FALSE
           END                                                                                AS weekend_indr
FROM (SELECT '2000-01-01'::DATE + SEQUENCE.DAY AS datum
      FROM GENERATE_SERIES(0, 18262) AS SEQUENCE (DAY)
      GROUP BY SEQUENCE.DAY) DQ
ORDER BY 1;

-- DROP TABLE IF EXISTS  bookings_dwh.Dim_Passengers CASCADE;
CREATE TABLE IF NOT EXISTS bookings_dwh.Dim_Passengers
(
    id           serial
        CONSTRAINT dim_passengers_pk PRIMARY KEY,
    passenger_id varchar NOT NULL
        CONSTRAINT dim_passengers_passenger_id_key
            UNIQUE,
    first_name   text,
    last_name    text,
    phone        varchar(15)
        CONSTRAINT dim_passengers_phone_key UNIQUE,
    email        varchar(150)
        CONSTRAINT dim_passengers_email_key UNIQUE

);
-- DROP TABLE IF EXISTS  bookings_dwh.Dim_Aircrafts CASCADE;
CREATE TABLE IF NOT EXISTS bookings_dwh.Dim_Aircrafts
(
    id    serial
        CONSTRAINT dim_aircrafts_pk PRIMARY KEY,
    code  varchar(20)
        CONSTRAINT dim_aircrafts_code_key UNIQUE,
    name  varchar(150),
    range int NOT NULL
);
/*
  aa.airport_code                                                                    AS arrival_airport_code,
       aa.airport_name                                                                    AS arrival_airport_name,
       aa.city                                                                            AS arrival_airport_city,
       aa.longitude                                                                       AS arrival_airport_longitude,
       aa.latitude                                                                        AS arrival_airport_latitude,
       aa.timezone                                                                        AS arrival_airport_timezone,
  */
-- DROP TABLE IF EXISTS  bookings_dwh.Dim_Airports CASCADE;
CREATE TABLE IF NOT EXISTS bookings_dwh.Dim_Airports
(
    id        serial
        CONSTRAINT dim_airports_pkey
            PRIMARY KEY,
    code      varchar(3)
        CONSTRAINT dim_airports_code_key
            UNIQUE,
    name      varchar(200),
    city      varchar(150),
    longitude decimal,
    latitude  decimal,
    timezone  varchar(100)
);
-- DROP TABLE IF EXISTS  bookings_dwh.Dim_Tariff CASCADE;
CREATE TABLE IF NOT EXISTS bookings_dwh.Dim_Tariff
(
    id     serial PRIMARY KEY,
    tariff varchar(20)
);

-- DROP TABLE IF EXISTS  bookings_dwh.Fact_Flights CASCADE;
CREATE TABLE IF NOT EXISTS bookings_dwh.Fact_Flights
(
    passenger_id               int NOT NULL REFERENCES bookings_dwh.Dim_Passengers,
    calendar_actual_arrival    int NOT NULL REFERENCES bookings_dwh.dim_calendar,
    calendar_actual_departure  int NOT NULL REFERENCES bookings_dwh.dim_calendar,
    departure_delay            int DEFAULT 0,
    arrival_delay              int DEFAULT 0,
    aircrafts                  int NOT NULL REFERENCES bookings_dwh.Dim_Aircrafts,
    arrival_airport_airports   int NOT NULL REFERENCES bookings_dwh.Dim_Airports,
    departure_airport_airports int NOT NULL REFERENCES bookings_dwh.Dim_Airports,
    tariff                     int NOT NULL REFERENCES bookings_dwh.Dim_Tariff,
    amount                     decimal
);
-- DROP TABLE IF EXISTS  bookings_dwh.Rejects CASCADE;
CREATE TABLE IF NOT EXISTS bookings_dwh.Rejects
(
    book_ref   char(6)  NOT NULL,
    ticket_no  char(13) NOT NULL,
    flight_id  integer  NOT NULL,
    data       json,
    created_at timestamp DEFAULT NOW()
);
