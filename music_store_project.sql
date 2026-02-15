 -- Project Database: music_store

DROP DATABASE IF EXISTS music_store;
CREATE DATABASE music_store;
USE music_store;

-- 1. ARTIST TABLE
CREATE TABLE IF NOT EXISTS artist (
    artist_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(120) NOT NULL
);

-- 2. ALBUM TABLE
CREATE TABLE IF NOT EXISTS album (
    album_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(160) NOT NULL,
    artist_id INT NOT NULL,
    FOREIGN KEY (artist_id) REFERENCES artist(artist_id)
);

-- 3. GENRE TABLE
CREATE TABLE IF NOT EXISTS genre (
    genre_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(120) NOT NULL
);

-- 4. TRACK TABLE
CREATE TABLE IF NOT EXISTS track (
    track_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    album_id INT NOT NULL,
    genre_id INT NOT NULL,
    composer VARCHAR(220),
    milliseconds INT NOT NULL,
    bytes INT,
    unit_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (album_id) REFERENCES album(album_id),
    FOREIGN KEY (genre_id) REFERENCES genre(genre_id)
);

-- 5. CUSTOMER TABLE
CREATE TABLE IF NOT EXISTS customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    company VARCHAR(160),
    address VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    phone VARCHAR(40),
    email VARCHAR(120) NOT NULL
);

-- 6. EMPLOYEE TABLE
CREATE TABLE IF NOT EXISTS employee (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    last_name VARCHAR(80) NOT NULL,
    first_name VARCHAR(80) NOT NULL,
    title VARCHAR(120),
    levels INT,
    reports_to INT,
    birth_date DATE,
    hire_date DATE,
    address VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    phone VARCHAR(40),
    fax VARCHAR(40),
    email VARCHAR(120),
    FOREIGN KEY (reports_to) REFERENCES employee(employee_id)
);

-- 7. INVOICE TABLE
CREATE TABLE IF NOT EXISTS invoice (
    invoice_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    invoice_date DATE NOT NULL,
    billing_address VARCHAR(200),
    billing_city VARCHAR(100),
    billing_state VARCHAR(100),
    billing_country VARCHAR(100),
    billing_postal_code VARCHAR(20),
    total DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

-- 8. INVOICE_LINE TABLE
CREATE TABLE IF NOT EXISTS invoice_line (
    invoice_line_id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id INT NOT NULL,
    track_id INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    FOREIGN KEY (invoice_id) REFERENCES invoice(invoice_id),
    FOREIGN KEY (track_id) REFERENCES track(track_id)
);

-- EASY LEVEL QUERIES
SELECT employee_id, first_name, last_name, title, levels
FROM employee ORDER BY levels DESC LIMIT 1;

SELECT billing_country, COUNT(*) AS invoice_count
FROM invoice GROUP BY billing_country ORDER BY invoice_count DESC;

SELECT invoice_id, customer_id, total
FROM invoice ORDER BY total DESC LIMIT 3;

SELECT billing_city, SUM(total) AS total_invoice_amount
FROM invoice GROUP BY billing_city ORDER BY total_invoice_amount DESC LIMIT 1;

SELECT c.customer_id, c.first_name, c.last_name, SUM(i.total) AS total_spent
FROM customer AS c JOIN invoice AS i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC LIMIT 1;

-- MODERATE LEVEL QUERIES
SELECT DISTINCT c.email, c.first_name, c.last_name
FROM customer AS c
JOIN invoice AS i ON c.customer_id = i.customer_id
JOIN invoice_line AS il ON i.invoice_id = il.invoice_id
JOIN track AS t ON il.track_id = t.track_id
JOIN genre AS g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock';

SELECT ar.artist_id, ar.name AS artist_name, COUNT(t.track_id) AS rock_track_count
FROM artist AS ar
JOIN album AS al ON ar.artist_id = al.artist_id
JOIN track AS t ON al.album_id = t.album_id
JOIN genre AS g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
GROUP BY ar.artist_id, ar.name
ORDER BY rock_track_count DESC LIMIT 10;

SELECT track_id, name, milliseconds
FROM track
WHERE milliseconds > (SELECT AVG(milliseconds) FROM track)
ORDER BY milliseconds DESC;

-- ADVANCED LEVEL QUERIES
WITH customer_artist_revenue AS (
    SELECT c.customer_id, c.first_name, c.last_name,
           ar.artist_id, ar.name AS artist_name,
           il.unit_price * il.quantity AS line_amount
    FROM invoice_line AS il
    JOIN invoice AS i ON il.invoice_id = i.invoice_id
    JOIN customer AS c ON i.customer_id = c.customer_id
    JOIN track AS t ON il.track_id = t.track_id
    JOIN album AS al ON t.album_id = al.album_id
    JOIN artist AS ar ON al.artist_id = ar.artist_id
)
SELECT customer_id, first_name, last_name, artist_id, artist_name,
       SUM(line_amount) AS total_spent_on_artist
FROM customer_artist_revenue
GROUP BY customer_id, first_name, last_name, artist_id, artist_name
ORDER BY customer_id, total_spent_on_artist DESC;

WITH genre_country_counts AS (
    SELECT i.billing_country, g.genre_id, g.name AS genre_name,
           COUNT(*) AS purchase_count
    FROM invoice_line AS il
    JOIN invoice AS i ON il.invoice_id = i.invoice_id
    JOIN track AS t ON il.track_id = t.track_id
    JOIN genre AS g ON t.genre_id = g.genre_id
    GROUP BY i.billing_country, g.genre_id, g.name
),
genre_country_ranked AS (
    SELECT billing_country, genre_id, genre_name, purchase_count,
           RANK() OVER (PARTITION BY billing_country ORDER BY purchase_count DESC) AS genre_rank
    FROM genre_country_counts
)
SELECT billing_country, genre_id, genre_name, purchase_count
FROM genre_country_ranked WHERE genre_rank = 1 ORDER BY billing_country;

WITH country_customer_spend AS (
    SELECT i.billing_country, c.customer_id, c.first_name, c.last_name,
           SUM(i.total) AS total_spent
    FROM invoice AS i
    JOIN customer AS c ON i.customer_id = c.customer_id
    GROUP BY i.billing_country, c.customer_id, c.first_name, c.last_name
),
country_customer_ranked AS (
    SELECT billing_country, customer_id, first_name, last_name, total_spent,
           RANK() OVER (PARTITION BY billing_country ORDER BY total_spent DESC) AS spend_rank
    FROM country_customer_spend
)
SELECT billing_country, customer_id, first_name, last_name, total_spent
FROM country_customer_ranked WHERE spend_rank = 1 ORDER BY billing_country;
