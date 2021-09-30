SELECT b.book_ref                                                            AS book_ref,
       b.book_date                                                           AS book_date,
       b.total_amount                                                        AS book_total_amount,
       t.ticket_no                                                           AS ticket_no,
       t.passenger_id                                                        AS passenger_id,
       SPLIT_PART(t.passenger_name, ' ', 1)                                  AS passenger_first_name,
       SPLIT_PART(t.passenger_name, ' ', 2)                                  AS passenger_last_name,
       t.contact_data::json ->> 'email'                                      AS passenger_email,
       t.contact_data::json ->> 'phone'                                      AS passenger_phone,
       tf.amount                                                             AS flight_amount,
       tf.fare_conditions                                                    AS flight_fare_conditions,
       f.flight_id                                                           AS flight_id,
       f.flight_no                                                           AS flight_no,
       f.scheduled_departure                                                 AS scheduled_departure,
       f.scheduled_arrival                                                   AS scheduled_arrival,
       f.actual_departure                                                    AS actual_departure,
       f.actual_arrival                                                      AS actual_arrival,
       EXTRACT(EPOCH FROM (f.actual_departure - f.scheduled_departure))::int AS departure_delay,
       EXTRACT(EPOCH FROM (f.actual_arrival - f.scheduled_arrival))::int     AS arrival_delay,
       f.status                                                              AS flight_status,
       aa.airport_code                                                       AS arrival_airport_code,
       aa.airport_name                                                       AS arrival_airport_name,
       aa.city                                                               AS arrival_airport_city,
       aa.longitude                                                          AS arrival_airport_longitude,
       aa.latitude                                                           AS arrival_airport_latitude,
       aa.timezone                                                           AS arrival_airport_timezone,
       da.airport_code                                                       AS departure_airport_code,
       da.airport_name                                                       AS departure_airport_name,
       da.city                                                               AS departure_airport_city,
       da.longitude                                                          AS departure_airport_longitude,
       da.latitude                                                           AS departure_airport_latitude,
       da.timezone                                                           AS departure_airport_timezone,
       bp.boarding_no                                                        AS boarding_no,
       a.aircraft_code                                                       AS aircraft_code,
       a.model                                                               AS aircraft_model,
       a.range                                                               AS aircraft_range,
       s.seat_no                                                             AS seat_no
FROM bookings.bookings b
         LEFT JOIN bookings.tickets t ON b.book_ref = t.book_ref
         LEFT JOIN bookings.ticket_flights tf ON t.ticket_no = tf.ticket_no
         LEFT JOIN bookings.flights f ON f.flight_id = tf.flight_id
         LEFT JOIN bookings.airports aa ON aa.airport_code = f.arrival_airport
         LEFT JOIN bookings.airports da ON da.airport_code = f.departure_airport
         LEFT JOIN bookings.aircrafts a ON a.aircraft_code = f.aircraft_code
         LEFT JOIN bookings.boarding_passes bp ON tf.ticket_no = bp.ticket_no AND tf.flight_id = bp.flight_id
         LEFT JOIN bookings.seats s ON bp.seat_no = s.seat_no AND s.aircraft_code = f.aircraft_code
WHERE f.status = 'Arrived';