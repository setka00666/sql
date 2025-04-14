--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите SQL-запрос, который выводит всю информацию о фильмах 
--со специальным атрибутом "Behind the Scenes".

select *
from film 
where special_features @> '{Behind the Scenes}'


--ЗАДАНИЕ №2
--Напишите еще 2 варианта поиска фильмов с атрибутом "Behind the Scenes",
--используя другие функции или операторы языка SQL для поиска значения в массиве.

select *
from film 
where special_features::text like '%Behind the Scenes%'

select *
from(select film_id, title, description, unnest(special_features)
     from film) t
where t.unnest = 'Behind the Scenes'
 

--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.
--Обязательное условие для выполнения задания: используйте запрос из задания 1, 
--помещенный в CTE. CTE необходимо использовать для решения задания.

with film as(select film_id
              from film 
                where special_features @> '{Behind the Scenes}')
select r.customer_id, count(f.film_id)
from film f
join inventory i on i.film_id = f.film_id 
join rental r on r.inventory_id = i.inventory_id
group by r.customer_id
order by r.customer_id 


--ЗАДАНИЕ №4
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".
--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--помещенный в подзапрос, который необходимо использовать для решения задания.

 select r.customer_id, count(f.film_id)
 from(select *
       from film 
         where special_features @> '{Behind the Scenes}') f
join inventory i on i.film_id = f.film_id 
join rental r on r.inventory_id = i.inventory_id
group by r.customer_id
order by r.customer_id



--ЗАДАНИЕ №5
--Создайте материализованное представление с запросом из предыдущего задания
--и напишите запрос для обновления материализованного представления

create materialized view customer_film_count as 
select r.customer_id, count(f.film_id)
from(select *
      from film 
        where special_features @> '{Behind the Scenes}') f
join inventory i on i.film_id = f.film_id 
join rental r on r.inventory_id = i.inventory_id
group by r.customer_id
order by r.customer_id

refresh materialized view customer_film_count


--ЗАДАНИЕ №6
--С помощью explain analyze проведите анализ стоимости выполнения запросов из предыдущих заданий и ответьте на вопросы:
--1. с каким оператором или функцией языка SQL, используемыми при выполнении домашнего задания: 
--поиск значения в массиве затрачивает меньше ресурсов системы;
--2. какой вариант вычислений затрачивает меньше ресурсов системы: 
--с использованием CTE или с использованием подзапроса.

1. Seq Scan on film  (cost=0.00..67.50 rows=538 width=386) (actual time=0.010..0.279 rows=538 loops=1)
  Filter: (special_features @> '{"Behind the Scenes"}'::text[])
  Rows Removed by Filter: 462
Planning Time: 0.062 ms
Execution Time: 0.297 ms

2.1 Seq Scan on film  (cost=0.00..72.50 rows=1 width=386) (actual time=0.013..0.501 rows=538 loops=1)
  Filter: ((special_features)::text ~~ '%Behind the Scenes%'::text)
  Rows Removed by Filter: 462
Planning Time: 0.054 ms
Execution Time: 0.518 ms

2.2 Subquery Scan on t  (cost=0.00..107.50 rows=10 width=145) (actual time=0.011..0.500 rows=538 loops=1)
  Filter: (t.unnest = 'Behind the Scenes'::text)
  Rows Removed by Filter: 1577
  ->  ProjectSet  (cost=0.00..82.50 rows=2000 width=145) (actual time=0.010..0.405 rows=2115 loops=1)
        ->  Seq Scan on film  (cost=0.00..65.00 rows=1000 width=172) (actual time=0.008..0.082 rows=1000 loops=1)
Planning Time: 0.060 ms
Execution Time: 0.522 ms

_____ВЫВОД: оператор @> затрачивает меньше ресурсов системы

3.Sort  (cost=673.98..675.48 rows=599 width=10) (actual time=6.335..6.350 rows=599 loops=1)
  Sort Key: r.customer_id
  Sort Method: quicksort  Memory: 43kB
  ->  HashAggregate  (cost=640.36..646.35 rows=599 width=10) (actual time=6.218..6.266 rows=599 loops=1)
        Group Key: r.customer_id
        Batches: 1  Memory Usage: 105kB
        ->  Hash Join  (cost=202.30..597.19 rows=8633 width=6) (actual time=0.948..5.302 rows=8608 loops=1)
              Hash Cond: (i.film_id = film.film_id)
              ->  Hash Join  (cost=128.07..480.67 rows=16044 width=4) (actual time=0.614..3.578 rows=16044 loops=1)
                    Hash Cond: (r.inventory_id = i.inventory_id)
                    ->  Seq Scan on rental r  (cost=0.00..310.44 rows=16044 width=6) (actual time=0.004..0.619 rows=16044 loops=1)
                    ->  Hash  (cost=70.81..70.81 rows=4581 width=6) (actual time=0.588..0.589 rows=4581 loops=1)
                          Buckets: 8192  Batches: 1  Memory Usage: 243kB
                          ->  Seq Scan on inventory i  (cost=0.00..70.81 rows=4581 width=6) (actual time=0.004..0.270 rows=4581 loops=1)
              ->  Hash  (cost=67.50..67.50 rows=538 width=4) (actual time=0.330..0.330 rows=538 loops=1)
                    Buckets: 1024  Batches: 1  Memory Usage: 27kB
                    ->  Seq Scan on film  (cost=0.00..67.50 rows=538 width=4) (actual time=0.009..0.295 rows=538 loops=1)
                          Filter: (special_features @> '{"Behind the Scenes"}'::text[])
                          Rows Removed by Filter: 462
Planning Time: 0.270 ms
Execution Time: 6.414 ms


4.Sort  (cost=673.98..675.48 rows=599 width=10) (actual time=6.093..6.107 rows=599 loops=1)
  Sort Key: r.customer_id
  Sort Method: quicksort  Memory: 43kB
  ->  HashAggregate  (cost=640.36..646.35 rows=599 width=10) (actual time=5.981..6.027 rows=599 loops=1)
        Group Key: r.customer_id
        Batches: 1  Memory Usage: 105kB
        ->  Hash Join  (cost=202.30..597.19 rows=8633 width=6) (actual time=1.045..5.073 rows=8608 loops=1)
              Hash Cond: (i.film_id = film.film_id)
              ->  Hash Join  (cost=128.07..480.67 rows=16044 width=4) (actual time=0.732..3.415 rows=16044 loops=1)
                    Hash Cond: (r.inventory_id = i.inventory_id)
                    ->  Seq Scan on rental r  (cost=0.00..310.44 rows=16044 width=6) (actual time=0.003..0.542 rows=16044 loops=1)
                    ->  Hash  (cost=70.81..70.81 rows=4581 width=6) (actual time=0.710..0.711 rows=4581 loops=1)
                          Buckets: 8192  Batches: 1  Memory Usage: 243kB
                          ->  Seq Scan on inventory i  (cost=0.00..70.81 rows=4581 width=6) (actual time=0.003..0.340 rows=4581 loops=1)
              ->  Hash  (cost=67.50..67.50 rows=538 width=4) (actual time=0.308..0.308 rows=538 loops=1)
                    Buckets: 1024  Batches: 1  Memory Usage: 27kB
                    ->  Seq Scan on film  (cost=0.00..67.50 rows=538 width=4) (actual time=0.009..0.272 rows=538 loops=1)
                          Filter: (special_features @> '{"Behind the Scenes"}'::text[])
                          Rows Removed by Filter: 462
Planning Time: 0.251 ms
Execution Time: 6.170 ms


_____ВЫВОД: в пользу подзапроса 

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выполняйте это задание в форме ответа на сайте Нетологии

--ЗАДАНИЕ №2
--Используя оконную функцию выведите для каждого сотрудника
--сведения о самой первой продаже этого сотрудника.





--ЗАДАНИЕ №3
--Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
-- 1. день, в который арендовали больше всего фильмов (день в формате год-месяц-день)
-- 2. количество фильмов взятых в аренду в этот день
-- 3. день, в который продали фильмов на наименьшую сумму (день в формате год-месяц-день)
-- 4. сумму продажи в этот день




