create table insurance (
    age integer,
    sex text,
    bmi real,
    children integer,
    smoker text,
    region text,
    charges real
);

select count(*) as total_rows from insurance;

select *
from insurance
where age is null
   or sex is null
   or bmi is null
   or children is null
   or smoker is null
   or region is null
   or charges is null;

select *
from insurance
where sex = ''
   or smoker = ''
   or region = '';

-- checked data if its clean or not so it wont make any error in the future  

-- 1. which combination of age group, smoker status, sex, and region has the highest average insurance charges?
with grouped as (
    select
        case
            when age < 30 then '0–29'
            when age between 30 and 39 then '30–39'
            when age between 40 and 49 then '40–49'
            when age between 50 and 59 then '50–59'
            else '60+'
        end as age_group,
        smoker,
        sex,
        region,
        avg(charges) over (
            partition by
                case
                    when age < 30 then '0–29'
                    when age between 30 and 39 then '30–39'
                    when age between 40 and 49 then '40–49'
                    when age between 50 and 59 then '50–59'
                    else '60+'
                end,
                smoker,
                sex,
                region
        ) as avg_charges
    from insurance
),
ranked as (
    select
        *,
        row_number() over (order by avg_charges desc) as rn
    from grouped
)
select age_group, smoker, sex, region, avg_charges
from ranked
where rn = 1;

-- 2. within each bmi category, how much higher are the average charges for smokers compared to non-smokers?
with base as (
  select
    case
      when bmi < 18.5 then 'underweight (<18.5)'
      when bmi < 25   then 'normal (18.5–24.9)'
      when bmi < 30   then 'overweight (25–29.9)'
      else 'obese (30+)'
    end as bmi_category,
    smoker,
    charges
  from insurance
),
calc as (
  select
    bmi_category,

    round(avg(case when smoker = 'yes' then charges end)
      over (partition by bmi_category), 2) as avg_smoker_charges,

    round(avg(case when smoker = 'no' then charges end)
      over (partition by bmi_category), 2) as avg_nonsmoker_charges,

    round(avg(case when smoker = 'yes' then charges end)
      over (partition by bmi_category), 2)
    - round(avg(case when smoker = 'no' then charges end)
      over (partition by bmi_category), 2) as diff_smoker_minus_nonsmoker,

    row_number() over (partition by bmi_category order by bmi_category) as rn
  from base
)
select
  bmi_category,
  avg_smoker_charges,
  avg_nonsmoker_charges,
  diff_smoker_minus_nonsmoker
from calc
where rn = 1
order by diff_smoker_minus_nonsmoker desc;


--3 Which factors (age group, BMI group, smoking status, and region) contribute the most to total insurance costs, and how do their impacts compare?
with base as (
  select
    charges,
    smoker,
    region,
    case
      when age between 18 and 25 then '18-25'
      when age between 26 and 40 then '26-40'
      when age between 41 and 60 then '41-60'
      else '60+'
    end as age_group,
    case
      when bmi < 18.5 then 'underweight'
      when bmi < 25 then 'normal'
      when bmi < 30 then 'overweight'
      else 'obese'
    end as bmi_group
  from insurance
),
factor_totals as (

  select
    'age_group' as factor,
    age_group as factor_level,
    round(sum(charges) over (partition by age_group), 2) as total_cost,
    row_number() over (partition by 'age_group', age_group order by age_group) as rn
  from base

  union all

  select
    'bmi_group' as factor,
    bmi_group as factor_level,
    round(sum(charges) over (partition by bmi_group), 2) as total_cost,
    row_number() over (partition by 'bmi_group', bmi_group order by bmi_group) as rn
  from base

  union all

  select
    'smoker' as factor,
    smoker as factor_level,
    round(sum(charges) over (partition by smoker), 2) as total_cost,
    row_number() over (partition by 'smoker', smoker order by smoker) as rn
  from base

  union all

  select
    'region' as factor,
    region as factor_level,
    round(sum(charges) over (partition by region), 2) as total_cost,
    row_number() over (partition by 'region', region order by region) as rn
  from base
),
final as (
  select
    factor,
    factor_level,
    total_cost,
    round(100.0 * total_cost / (select sum(charges) from base), 2) as pct_of_total
  from factor_totals
  where rn = 1
)
select *
from final
order by factor, total_cost desc;



--4.Which types of people are responsible for most of the insurance money being spent?
with base as (
  select
    charges,
    smoker,
    case
      when age between 18 and 25 then '18-25'
      when age between 26 and 40 then '26-40'
      when age between 41 and 60 then '41-60'
      else '60+'
    end as age_group,
    case
      when bmi < 18.5 then 'underweight'
      when bmi < 25 then 'normal'
      when bmi < 30 then 'overweight'
      else 'obese'
    end as bmi_group
  from insurance
),
seg as (
  select
    age_group,
    bmi_group,
    smoker,

    count(*) over (partition by age_group, bmi_group, smoker) as customer_count,
    round(sum(charges) over (partition by age_group, bmi_group, smoker), 2) as segment_total_cost,
    round(avg(charges) over (partition by age_group, bmi_group, smoker), 2) as avg_cost_per_customer,

    round(
      100.0 * (sum(charges) over (partition by age_group, bmi_group, smoker))
      / (sum(charges) over ()),
      2
    ) as pct_of_total_cost,

    row_number() over (partition by age_group, bmi_group, smoker order by age_group) as rn
  from base
)
select
  age_group,
  bmi_group,
  smoker,
  customer_count,
  segment_total_cost,
  pct_of_total_cost,
  avg_cost_per_customer
from seg
where rn = 1
order by segment_total_cost desc;


--5. What percentage of the total insurance cost comes from the top 10% most expensive customers, and how does this compare between smokers and non-smokers?
with ranked as (
  select
    *,
    ntile(10) over (order by charges desc) as decile
  from insurance
),
top10 as (
  select *
  from ranked
  where decile = 1
),
calc as (
  select
    smoker,
    sum(charges) over () as top10_total_cost,
    sum(charges) over (partition by smoker) as top10_cost_by_smoker,
    (select sum(charges) from ranked) as overall_total_cost
  from top10
),
dedup as (
  select
    *,
    row_number() over (partition by smoker order by smoker) as rn
  from calc
)
select
  'top 10% (all)' as group_name,
  round(100.0 * (select sum(charges) from top10) / (select sum(charges) from ranked), 2) as pct_of_total_cost

union all

select
  case 
    when smoker = 'yes' then 'top 10% smokers'
    else 'top 10% non-smokers'
  end as group_name,
  round(100.0 * top10_cost_by_smoker / overall_total_cost, 2) as pct_of_total_cost
from dedup
where rn = 1;
