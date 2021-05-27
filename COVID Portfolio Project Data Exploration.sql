
-- Source data provided at https://ourworldindata.org/covid-deaths, accessed 5/25/2021
-- 1) Preview raw data sets
select * 
from dbo.CovidDeaths
order by 3,4 -- order by 3rd, then 4th column. Doesn't work in GROUP BY, must explicitly state column name


select *
from dbo.CovidVaccinations
order by 3,4


-- 2) Restrict output to specify only columns of interest
select location, date, total_cases, new_cases, total_deaths, population
from dbo.CovidDeaths
order by 1,2


select location, date, total_tests, new_tests, total_vaccinations, new_vaccinations
from dbo.CovidVaccinations
order by 1,2


-- 3) Total Cases vs Total deaths, IFR or Infection Fatality Ratio
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as InfectionFatalityRatio
from dbo.CovidDeaths
order by 1,2


-- 4) Only return most recent reportings
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as InfectionFatalityRatio
from dbo.CovidDeaths
where date = '2020-05-25 00:00:00.000'
order by 1,2


-- 5) More complicated query, but doesn't require manually updating date, requires joining a derived table
select a.location, a.MostRecentDate, total_cases, total_deaths, (total_deaths/total_cases)*100 as InfectionFatalityRatio
	from(select location, max(date) as MostRecentDate
		from dbo.CovidDeaths
		group by location) as a
	join dbo.CovidDeaths as b ON a.location = b.location
	and a.MostRecentDate = b.date
order by a.location


-- 6) Only query a single location, lets choose USA
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as InfectionFatalityRatio
from dbo.CovidDeaths
where location like '%states'
order by 1,2


-- 7) Slap the where location clause into query 5), lines 37-44, to return a single result for single location
select a.location, a.MostRecentDate, total_cases, total_deaths, (total_deaths/total_cases)*100 as InfectionFatalityRatio
	from(select location, max(date) as MostRecentDate
		from dbo.CovidDeaths
		group by location) as a
	join dbo.CovidDeaths as b ON a.location = b.location
	and a.MostRecentDate = b.date
where a.location like '%states'


-- 8) Total Cases vs Population, infectivity
select location, date, population, total_cases, (total_cases/population)*100 as InfectionRate
from dbo.CovidDeaths
order by 1,2


-- 9) Now restrict to single country, picking USA
select location, date, population, total_cases, (total_cases/population)*100 as InfectionRate
from dbo.CovidDeaths
where location like '%states'
order by 1,2


-- 10) Narrow down to most recent date for all locations
select a.location, a.MostRecentDate, population, total_cases, (total_cases/population)*100 as InfectionRate
	from(select location, max(date) as MostRecentDate
		from dbo.CovidDeaths
		group by location) as a
	join dbo.CovidDeaths as b ON a.location = b.location
	and a.MostRecentDate = b.date
--order by a.location
order by InfectionRate desc


-- 11) Alternative method to 10), doesn't use date/derived table
select location, population, max(total_cases) as top_infection_count, (max(total_cases)/population)*100 as InfectionRate
from dbo.CovidDeaths
group by location, population
--order by location
order by InfectionRate desc


-- 12) Now narrow down location to most recent date for a singular location
select a.location, a.MostRecentDate, population, total_cases, (total_cases/population)*100 as InfectionRate
	from(select location, max(date) as MostRecentDate
		from dbo.CovidDeaths
		group by location) as a
	join dbo.CovidDeaths as b ON a.location = b.location
	and a.MostRecentDate = b.date
where a.location like '%states'


-- 13) Alternative to 12), once again forgoing date/derived table
select location, population, max(total_cases) as top_infection_count, (max(total_cases)/population)*100 as InfectionRate
from dbo.CovidDeaths
where location like '%states'
group by location, population


-- 14) Sorting locations by highest death count per population
select location, population, max(cast(total_deaths as int)) as TotalDeaths,
(max(cast(total_deaths as int))/population)*100 as MortalityRate 
from dbo.CovidDeaths
group by location, population
order by TotalDeaths desc


-- 15) Narrow the results of 14) to only consider continents/world instead of both continents and countries
select location, population, max(cast(total_deaths as int)) as TotalDeaths,
(max(cast(total_deaths as int))/population)*100 as MortalityRate 
from dbo.CovidDeaths
where continent is null -- change to not null to exclude continents and only look at countries
group by location, population
order by TotalDeaths desc


-- 16) World population, cases, deaths, infectivity, mortality at current date
select a.location, a.MostRecentDate, population, total_cases, 
(total_cases/population)*100 as InfectionRate, total_deaths, 
(total_deaths/total_cases)*100 as InfectionFatalityRatio,
(total_deaths/population)*100 as MortalityRate
	from(select location, max(date) as MostRecentDate
		from dbo.CovidDeaths
		group by location) as a
	join dbo.CovidDeaths as b ON a.location = b.location
	and a.MostRecentDate = b.date
where a.location like 'World'
-- WHO reports 167,492,769 confirmed cases of COVID-19 as of 5/26/2021 https://covid19.who.int/
-- Our query gives 167,848,205


------------ VACCINATIONS ---------------

-- 17) How many vaccinations occur every day, per country?
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, vac.total_vaccinations
from dbo.CovidDeaths as dea
join dbo.CovidVaccinations as vac
on dea.location = vac.location
and dea.date = vac.date
where vac.total_vaccinations is not null
and dea.continent is not null
order by 1,2,3


-- 18) What if vac.total_vaccinations didn't exist?
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
,sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as TotalVaccinationsByDate
--, (TotalVaccinationsByDate/dea.population) * 100 -- problem for next query to address
from dbo.CovidDeaths as dea
join dbo.CovidVaccinations as vac
on dea.location = vac.location
and dea.date = vac.date
--where vac.new_vaccinations is not null --harder to read, but good to double check nulls aren't breaking the rolling count
where dea.continent is not null
order by 1,2,3


-- In Query 18), we wanted to get the percentage of total vaccinations by a certain date, but ran into the problem that you
-- can't reference an alias in select because of the order in which SQL evaluates queries. There are two solutions available to us.
-- 19) CTE solution
With PopsVacByDate (continent, location, date, population, new_vaccinations, TotalVaccinationsByDate)--, VacByDatePercentage)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
,sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as TotalVaccinationsByDate
from dbo.CovidDeaths as dea
join dbo.CovidVaccinations as vac
on dea.location = vac.location
and dea.date = vac.date
where vac.new_vaccinations is not null
and dea.continent is not null
--order by 1,2,3
)
Select *,(TotalVaccinationsByDate/population) * 100 as VacByDatePercentage
from PopsVacByDate
order by 1,2,3
--order by VacByDatePercentage desc


-- 20) In 19), Some countries report a higher than 100% VaccinationPercentage by this measure
-- Will compare with original total_vaccinations data in this query.
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, vac.total_vaccinations
,(vac.total_vaccinations / dea.population)*100 as VacPercentage
from dbo.Coviddeaths as dea
join dbo.Covidvaccinations as vac
on dea.location = vac.location
and dea.date = vac.date
where vac.total_vaccinations is not null
and dea.continent is not null
--order by 1,2,3
order by VacPercentage desc
-- Difference in final result, but still over 100%, would consider cleaning/discussion with other team members regarding it.


-- 21) Temp table solution to 18)
Drop Table If Exists dbo.#PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
TotalVaccinationsByDate numeric
)

Insert into #PercentPopulationVaccinated

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
,sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as TotalVaccinationsByDate
from dbo.CovidDeaths as dea
join dbo.CovidVaccinations as vac
on dea.location = vac.location
and dea.date = vac.date
where vac.new_vaccinations is not null
and dea.continent is not null
order by 1,2,3

select *, (TotalVaccinationsByDate/population) * 100 as VacByDatePercentage
from #PercentPopulationVaccinated
order by continent, location, date


-- 22) Creating views of interesting queries for individual export to Tableau for visualizations
Drop View If Exists PercentPopulationVaccinated
GO
Create View PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
,sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as TotalVaccinationsByDate
from dbo.CovidDeaths as dea
join dbo.CovidVaccinations as vac
on dea.location = vac.location
and dea.date = vac.date
where vac.new_vaccinations is not null
and dea.continent is not null


---- Further work to consider, creating views of interesting queries for future reference

