--COVID-19 Analysis - database:https://ourworldindata.org/covid-deaths
--note that there's a limit to which this data is accurate, 
--for example, the 'population' column data remains static in all of the dates;
--total_cases accumulates the cases that occured at any time of the date range,
--and only grows in number, unlike the reality, where people are no longer counted
--as "covid contractors". This can lead to an anomaly in which countries reach a 50%
--of covid contractors out of their population. However, at times, this database does work 
--and allow some interesting insights regarding covid at its peaks and in tune with
--lockdowns and vaccination phases.

--Selecting the data in use

Select location, date, total_cases, new_cases, total_deaths, population
From	COVID.dbo.CovidDeaths
order by	1,2

-- Selecting data for total deaths/cases
-- It will show the death percentage out of total cases in a country.
--(I used the conditional CASE because the result of integer division in a column
--that has nulls is sometimes truncated and shows only zeros, this should avoid it).

Select location,date,total_cases,total_deaths,
	CASE
		WHEN total_cases IS NULL OR total_cases=0 THEN 0
		ELSE (total_deaths*1.0 / total_cases)*100
	END AS death_percentage
From COVID.dbo.CovidDeaths
Order by 1, 2;

--Selecting data for death % in Israel
--Shows the likelihood of dying if you contract covid in Israel (any country can be chosen)

Select location,date,total_cases,total_deaths,
	CASE
		WHEN total_cases IS NULL OR total_cases=0 THEN 0
		ELSE (total_deaths*1.0 / total_cases)*100
	END AS death_percentage
From COVID.dbo.CovidDeaths
Where	location like 'Israel'
Order by 1, 2;

--Checking for the same data in the US

Select location,date,total_cases,total_deaths,
	CASE
		WHEN total_cases IS NULL OR total_cases=0 THEN 0
		ELSE (total_deaths*1.0 / total_cases)*100
	END AS death_percentage
From COVID.dbo.CovidDeaths
Where	location like '%states%'
Order by 1, 2;

-- Looking at total cases vs population
-- first from Israel and than from the US

-- Shows the percentage of covid cases out of the entire Israeli population

Select location, date,total_cases,population,
	CASE
		WHEN total_cases IS NULL OR total_cases=0 THEN 0
		ELSE (total_cases*1.0 / population)*100
	END AS contraction_percentage
From COVID.dbo.CovidDeaths
Where	location like 'Israel'
Order by 1, 2;

-- Shows the percentage of covid cases out of the entire US population


Select location, date,total_cases,population,
	CASE
		WHEN total_cases IS NULL OR total_cases=0 THEN 0
		ELSE (total_cases*1.0 / population)*100
	END AS contraction_percentage
From COVID.dbo.CovidDeaths
Where	location like '%states%'
Order by 1, 2;

-- looking at countries with the highest infection count compared to population.
--Here are two ways to avoid the null values, a conditional and using COALESCE.

Select location, population, COALESCE(MAX(total_cases*1.0/population)*100,'0') as perc_infected,
	COALESCE(MAX(total_cases),'0') as HighestInfectionCount
	--CASE
	--	WHEN MAX(total_cases)IS NULL OR MAX(total_cases)=0 THEN 0
	--	ELSE MAX(total_cases*1.0)/population*100
	--END AS perc_infected
From	COVID.dbo.CovidDeaths
Group by	location, population
Order by	perc_infected DESC;

--As mentioned before, looking at the data from 2023 perspective creates some anomalies.
--the previous query shows the accumulated total cases vs the population count from the
--begining of the pandemic.

--This query will attempt to return a less distorted picture for
--the highest infection count and the percentage of infected, by focusing on a
--shorter period and looking at pandemic peaks. Later on I will employ some other data
--in order to create even a clearer view of the pandemic.

Select location, population, COALESCE(MAX(total_cases*1.0/population)*100,'0') as perc_infected,
	COALESCE(MAX(total_cases),'0') as HighestInfectionCount
--	CASE
--		WHEN MAX(total_cases)IS NULL OR MAX(total_cases)=0 THEN 0
--		ELSE MAX(total_cases*1.0)/population*100
--	END AS perc_infected
From	COVID.dbo.CovidDeaths
Where	date BETWEEN '2021-10-20' AND '2022-05-31'
Group by location, population
Order by perc_infected DESC;

--After looking at the numbers of infected people, I will turn to the gloomier side
--of this covid overview - Hoe many people have died?

Select location, MAX(total_deaths) as Total_Death_count
From	COVID.dbo.CovidDeaths
Group by	location
Order by	2 DESC;

--However, this query returns also groupings which are inherent in the database,
--such as continents, socio-economical class, or 'World'.
--The following query will clean that out by WHERE filtering and looking only
--for rows where the 'continent' is not null (if it is null, it means that
--the the 'country' column will be a name of one of the groups present in this database).

Select location, MAX(total_deaths) as Total_Death_count
From	COVID.dbo.CovidDeaths
Where	continent is not NULL ----In general, this can be added to the above queries.
Group by	location
Order by	2 DESC;

--So, the last queries showed the data by country, let's see how thing are from
--the continent level.

Select location, MAX(total_deaths) as Total_Death_count
--I could've selected the continent column to get this query, however, this database
--has its flaws and for some reason 'North America' counts only the US, without Canada.
From	COVID.dbo.CovidDeaths
Where	continent is NULL ----now I want this to be null, because I'm looking for continents.
Group by	location
Order by	2 DESC; ----This will also return socio-economic class

--Showing the continent with the highest death count (without classes and other stuff, just continents)

Selec	continent, MAX(total_deaths) as Total_Death_count
From	COVID.dbo.CovidDeaths
Where	continent is not NULL
Group by continent
Order by 2 DESC;

-- Looking at global covid numbers.

Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
	COALESCE(SUM(cast(new_deaths AS INT)) * 1.0 / NULLIF(SUM(new_cases), 0), 0)*100 AS Death_perc
From COVID.dbo.CovidDeaths
Where continent is not NULL
Group by date
Order by 1,2;

--Now, if we take out the date column out of the query, we can look at those stats on a global scale, 
--but without the daily breakdown.

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
	COALESCE(SUM(cast(new_deaths AS INT)) * 1.0 / NULLIF(SUM(new_cases), 0), 0)*100 AS Death_perc
From COVID.dbo.CovidDeaths
Where continent is not NULL
Order by 1,2;

--The death percentage changed throughout the pandemic, and while in late 2023 we are
--dealing with a little less than 1% death percentage, earlier periods suffered a much higher
--death percentage. I'll demonstrate this below:

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
	COALESCE(SUM(cast(new_deaths AS INT)) * 1.0 / NULLIF(SUM(new_cases), 0), 0)*100 AS Death_perc
From COVID.dbo.CovidDeaths
----Where continent is not NULL
	----AND date BETWEEN '2020-03-01' AND '2020-06-01' ----one of the toughest peaks of the pandemic int the UK.
Where continent is not NULL
	AND date BETWEEN '2020-12-01' AND '2021-04-01' ----The toughest period for the UK, the US, France and Germany,
	----during which the UK surpassed the 20% death percentage.
Order by 1,2;

--We can also isolate the top N in death percentage for a clearer view on countries which suffered the most deaths vs cases.

Select TOP (10) location, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
	COALESCE(SUM(cast(new_deaths AS INT)) * 1.0 / NULLIF(SUM(new_cases), 0), 0)*100 AS Death_perc
From COVID.dbo.CovidDeaths
Where continent is not null
	--AND date BETWEEN '2020-03-01' AND '2020-06-01'
	--AND date BETWEEN '2020-12-01' AND '2021-04-01'
Group by location
Order by Death_perc DESC;

--These stats raise questions regarding data collection and reliability in the top 10 countries, and leads to the
--the hypothesis that every analytical work has to be double and triple checked, in order to claim that our
--findings are backed by data and are accurate.


--Moving on to the other table in this covid database, containing vaccinations info.

Select *
From COVID..CovidVaccinations;

--Joining the tables and looking at Total Population vs. Vaccinations.
--Firstly, by creating a rolling count of the number of vaccinations administered to the population.

Select deaths.continent, deaths.location, deaths.date, deaths.population, vacs.new_vaccinations,
	SUM(cast(vacs.new_vaccinations as bigint)) OVER (Partition by deaths.location Order by deaths.location, deaths.date)
		as rolling_vacs_count
From COVID..CovidDeaths as deaths
Join COVID..CovidVaccinations as vacs
	On deaths.location = vacs.location
	and deaths.date = vacs.date
Where deaths.continent is not null
Order by 2,3;

--This is a kinda complex query, I can turn it into a CTE and use it later for other calculations.

With Pop_VS_Vacs (Continent, Location, Date, Population, New_Vaccinations,  Rolling_Vacs_Count)
as 
(
Select deaths.continent, deaths.location, deaths.date, deaths.population, vacs.new_vaccinations,
	SUM(Convert(bigint,vacs.new_vaccinations)) OVER (Partition by deaths.location Order by deaths.location, deaths.date)
		as rolling_vacs_count
From COVID..CovidDeaths as deaths
Join COVID..CovidVaccinations as vacs
	On deaths.location = vacs.location
	and deaths.date = vacs.date
Where deaths.continent is not null
----Order by 2,3;--cannot use order by inside this.
)
Select *, ((rolling_vacs_count)*1.0/Population)*100 as Perc_Vaccinated
From Pop_VS_Vacs;


