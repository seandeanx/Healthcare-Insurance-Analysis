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
WITH base AS (
  SELECT
    charges,
    smoker,
    region,
    CASE
      WHEN age < 30 THEN '0–29'
      WHEN age BETWEEN 30 AND 39 THEN '30–39'
      WHEN age BETWEEN 40 AND 49 THEN '40–49'
      WHEN age BETWEEN 50 AND 59 THEN '50–59'
      ELSE '60+'
    END AS age_group,
    CASE
      WHEN bmi < 18.5 THEN 'underweight'
      WHEN bmi < 25 THEN 'normal'
      WHEN bmi < 30 THEN 'overweight'
      ELSE 'obese'
    END AS bmi_group
  FROM insurance
),
factor_totals AS (

  SELECT
    'age_group' AS factor,
    age_group AS factor_level,
    ROUND(SUM(charges) OVER (PARTITION BY age_group), 2) AS total_cost,
    ROW_NUMBER() OVER (PARTITION BY 'age_group', age_group ORDER BY age_group) AS rn
  FROM base

  UNION ALL

  SELECT
    'bmi_group' AS factor,
    bmi_group AS factor_level,
    ROUND(SUM(charges) OVER (PARTITION BY bmi_group), 2) AS total_cost,
    ROW_NUMBER() OVER (PARTITION BY 'bmi_group', bmi_group ORDER BY bmi_group) AS rn
  FROM base

  UNION ALL

  SELECT
    'smoker' AS factor,
    smoker AS factor_level,
    ROUND(SUM(charges) OVER (PARTITION BY smoker), 2) AS total_cost,
    ROW_NUMBER() OVER (PARTITION BY 'smoker', smoker ORDER BY smoker) AS rn
  FROM base

  UNION ALL

  SELECT
    'region' AS factor,
    region AS factor_level,
    ROUND(SUM(charges) OVER (PARTITION BY region), 2) AS total_cost,
    ROW_NUMBER() OVER (PARTITION BY 'region', region ORDER BY region) AS rn
  FROM base
),
final AS (
  SELECT
    factor,
    factor_level,
    total_cost,
    ROUND(100.0 * total_cost / (SELECT SUM(charges) FROM base), 2) AS pct_of_total
  FROM factor_totals
  WHERE rn = 1
)
SELECT *
FROM final
ORDER BY factor, total_cost DESC;


--4.Which types of people are responsible for most of the insurance money being spent?
with base as (
  select
    charges,
    smoker,
    case
      when age < 30 then '0–29'
      when age between 30 and 39 then '30–39'
      when age between 40 and 49 then '40–49'
      when age between 50 and 59 then '50–59'
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



-- 5. For each age group and BMI group, how much more do smokers pay on average compared to non-smokers?

with base as (
  select
    charges,
    smoker,
    case
      when age < 30 then '0-29'
      when age between 30 and 39 then '30-39'
      when age between 40 and 49 then '40-49'
      when age between 50 and 59 then '50-59'
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
    avg(case when smoker = 'yes' then charges end) as avg_smoker_charges,
    avg(case when smoker = 'no'  then charges end) as avg_nonsmoker_charges
  from base
  group by age_group, bmi_group
),
final as (
  select
    age_group,
    bmi_group,
    round(avg_smoker_charges, 2) as avg_smoker_charges,
    round(avg_nonsmoker_charges, 2) as avg_nonsmoker_charges,
    round(
      case
        when avg_smoker_charges is null or avg_nonsmoker_charges is null then null
        else avg_smoker_charges - avg_nonsmoker_charges
      end
    , 2) as smoker_premium,
    rank() over (
      order by
        case
          when avg_smoker_charges is null or avg_nonsmoker_charges is null then null
          else avg_smoker_charges - avg_nonsmoker_charges
        end desc
    ) as premium_rank
  from seg
)
select *
from final
where smoker_premium is not null
order by smoker_premium desc;


