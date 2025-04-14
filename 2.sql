--=============== МОДУЛЬ 3. ОСНОВЫ SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания, 
--город и страну проживания.

select concat(c.first_name, ' ', c.last_name),a.address, ci.city, co.country
from customer c
join address a on c.address_id = a.address_id 
join city ci on a.city_id = ci.city_id 
join country co on ci.country_id = co.country_id 

--ЗАДАНИЕ №2
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.

select s.store_id, count(c.customer_id)
from store s 
join customer c on c.store_id =s.store_id
group by s.store_id 

--Доработайте запрос и выведите только те магазины, 
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам 
--с использованием функции агрегации.

select s.store_id, count(c.customer_id)
from store s 
join customer c on c.store_id =s.store_id
group by s.store_id 
having count(c.customer_id) > 300

-- Доработайте запрос, добавив в него информацию о городе магазина, 
--а также фамилию и имя продавца, который работает в этом магазине.

select s.store_id, count(c.customer_id), ci.city, concat(st.last_name, ' ', st.first_name) 
from store s 
join customer c on c.store_id =s.store_id
join address a on s.address_id = a.address_id
join city ci on a.city_id = ci.city_id
join staff st on s.store_id = st.store_id 
group by s.store_id, ci.city_id, st.staff_id 
having count(c.customer_id) > 300

--ЗАДАНИЕ №3
--Выведите ТОП-5 покупателей, 
--которые взяли в аренду за всё время наибольшее количество фильмов

select concat(c.last_name, ' ', c.first_name), count(r.customer_id) 
from customer c 
join rental r on c.customer_id = r.customer_id 
group by c.customer_id 
order by count(r.customer_id)desc
limit 5

--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма

select concat(c.last_name, ' ', c.first_name) , count(r.rental_id),
       round(sum(p.amount)), min(p.amount), max(p.amount) 
from customer c 
join rental r on c.customer_id = r.customer_id
join payment p on r.rental_id = p.rental_id 
group by c.customer_id

--ЗАДАНИЕ №5
--Используя данные из таблицы городов, составьте все возможные пары городов так, чтобы 
--в результате не было пар с одинаковыми названиями городов. Решение должно быть через Декартово произведение.
 
select distinct c.city, ci.city as "city пара"
from city c 
cross join city ci 
where ci.city > c.city

--ЗАДАНИЕ №6
--Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date) и 
--дате возврата (поле return_date), вычислите для каждого покупателя среднее количество 
--дней, за которые он возвращает фильмы. В результате должны быть дробные значения, а не интервал.

 select customer_id, (max(return_date::date) - min(rental_date::date)), round(avg(date_part('day', return_date - rental_date))::numeric, 2)
 from rental 
 group by 1
 
select r.customer_id, round(avg(date_part('day', r.return_date - r.rental_date)))
from rental r 
group by r.customer_id 

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Посчитайте для каждого фильма сколько раз его брали в аренду и значение общей стоимости аренды фильма за всё время.
select t.*
from(select f.title, count(r.rental_id), i.film_id, sum(p.amount)
     from film f
     join inventory i on f.film_id = i.film_id 
     join rental r on i.inventory_id = r.inventory_id
     join payment p on r.rental_id = p.rental_id
     group by i.film_id , f.title) t 
order by t.title



--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания и выведите с помощью него фильмы, которые отсутствуют на dvd дисках.

select *
from film f
inner join (select f.film_id
	from film f
	except
	select i.film_id
	from inventory i ) ii on ii.film_id = f.film_id 



--ЗАДАНИЕ №3
--Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку "Премия".
--Если количество продаж превышает 7300, то значение в колонке будет "Да", иначе должно быть значение "Нет".


SELECT 	
	s.first_name,
	s.last_name,
	count(p.rental_id),
	CASE 
		WHEN count(p.rental_id)>7300 THEN 'Да'
		ELSE 'Нет'
	END AS "Премия"
FROM 
	staff s
LEFT JOIN payment p ON p.staff_id = s.staff_id 
GROUP BY s.staff_id




