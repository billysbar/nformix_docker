CREATE DATABASE testdb with log;

CREATE TABLE customer(id bigserial primary key, name varchar(255));

DATABASE testdb;

INSERT INTO customer (name) VALUES ( "Shani" );
INSERT INTO customer (name) VALUES ( "Billy" );

-- https://ifmx.wordpress.com/tag/json/
-- mongo
CREATE TABLE places (
  place_id SERIAL,
  numberOfVisitorsPerYear INT,
  place BSON
);

INSERT INTO places VALUES (0, 500000, '{city: "Zagreb"}'::JSON);
INSERT INTO places VALUES (0, 600000, '{city: "Pula", country: "Croatia", population: 57000}'::JSON);
INSERT INTO places VALUES (0, 20000, '{mountain: "Velebit", country: "Croatia", height: 1757}'::JSON);
INSERT INTO places VALUES (0, 1000000, '{national_park: "Plitvice", country: "Croatia"}'::JSON);

-- SELECT place_id, numberOfVisitorsPerYear, place::JSON FROM places
