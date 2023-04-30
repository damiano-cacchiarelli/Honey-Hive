/* -------------------------------------------------------------------------- */
/*                               CONST & AGENTS                               */
/* -------------------------------------------------------------------------- */

/*Bees*/
const ENERGY = 10;                          /* The energy available to a bee. A bee with 0 energy cannot perform activities */
const POISONING = 10;                       /* The poisoning level of a bee */

/*Flowers*/
const SPECIES = 3;                          /* The max number of flower species in the simulation */
const NECTAR_AVAILABLE = 2;                 /* 1 if the flower has nectar available; 0 if not available */

/*Hive*/            
const FOOD_STORAGE = 1000;                  /* The amount of nectar that can be stored */

/* --------------------------------- Agents --------------------------------- */

species Q of [0, ENERGY];                               /* Queen */
species WB of [0, ENERGY]*[0, POISONING];               /* Worker Bee */

species H;                                              /* Honey Storage */
species N;                                              /* Nectar Storage */

species F of [0, SPECIES]*[0, NECTAR_AVAILABLE];        /* Flowers */

species DQ;                                             /* Death Queen */
species DW;                                             /* Death Worker */

/*Debug*/
species N_F;   /*Nectar used for food */
species N_H;   /*Nectar used for Honey*/
species N_QF;  /*Nectar used for Queen food */

species BB;    /*Born Bees*/

/* ---------------------------------- Rates ---------------------------------- */

const eat_rate = 0.90 ;

const queen_mortality_rate = 0.0001 ;
const queen_metabolism = 0.25 ;
const bee_birth_rate = 1.0 ;

const worker_metabolism = 0.30 ;
const worker_mortality_rate = 0.25 ;

const worker_store_nectar = 0.9 ;
const worker_produce_honey_rate = 0.5 ;

const flower_pruduce_nectar_rate = 0.2 ;


/* --------------------------------- Params --------------------------------- */

param temperature = 31 ;
param rainfall_rate = 1;
param humidity = 5 ;
param flowers_biodiversity = 1 ;
param pesticide_exposure_rate = 0.0 ;

/* ---------------------------------- Math functions --------------------------------- */

/*
{ID: WF_1} Workers population function:

    1/4^(#workers - critical_workers_population/3)

#workers:
    The total worker bees in the hive;

critical_workers_population:
    The minimum number of bee that allow the queen to survive; If the number of bees falls below this
    threshold, the probability of queen death increase exponentially;

*/
const critical_workers_population = 10;

/*
{ID: HF_1} Humidity function:

Describe the probability to produce honey at a given humidity;

    1/(humidity - ideal_humidity)^2humidity_impact

ideal_humidity:
    Represent the percentage of ideal humidity in the hive;
    Integer; Ranges between 0 and 9 -> [0, 9];
    E.g :   4 equal to 50% of humidity;
            5 equal to 60% of humidity;

humidity_impact:
    Defines how fast the function for humidity goes up;
    Integer; Ranges between 0 and 10 -> [0, 10];
    The smaller the number, the more the rate of humidity increases around the ideal_humidity value;

*/
const ideal_humidity = 5;
const humidity_impact = 1;
const humidity_rate = 1/(((humidity - ideal_humidity)^2*humidity_impact)+1);


/*
{ID: TF_1} Temperature function:

Describe the probability of death of a bee at a given temperature;

    0.9 - 0.9/(1 + (2*(temperature - ideal_temperature)/delta_temperature)^2temperature_impact)

temperature:
    The temperature in the hive;
    Decimal; Renges between 5 and 60 -> [5, 60];
 
ideal_temperature:
    Represent the ideal temperature in the hive for the bees survival;

temperature_impact:
    Defines how fast the function for humidity goes down;
    Integer; Ranges between 1 and 100 -> [1, 100];
    The smaller the number, the more the rate of bee survival increases around the ideal_temperature value;

*/
const ideal_temperature = 31;
const delta_temperature = 8;
const temperature_impact = 2;
const temperature_rate = 1 - 0.9/(1 + (2*(temperature - ideal_temperature)/delta_temperature)^(2*temperature_impact));

/* -------------------------------------------------------------------------- */
/*                                   LABELS                                   */
/* -------------------------------------------------------------------------- */

/*Flowers*/
label flowers = { F[s, n for s in [0,SPECIES] and n in [0, NECTAR_AVAILABLE]] }
label flowers_nectar_available = { F[s, 1 for s in [0,SPECIES]] }

/*Bees*/
label workers = { WB[e, p for e in [1,ENERGY] and p in [0,POISONING]] }
label infected_workers = { WB[e, p for e in [0,ENERGY] and p in [1,POISONING]] }

/*Hive*/            
label used_storage = { N }

/* -------------------------------------------------------------------------- */
/*                                    RULES                                   */
/* -------------------------------------------------------------------------- */

/* ---------------------------------- Queen --------------------------------- */

/*
>> QUEEN EATS <<

Results:
    Increase ENERGY;
    Descrease NECTAR Storage (N);

Base rates: 
    eat_rate;

Impacts:
    Residual ENERGY (Low ENERGY increase eat_rate);

    (1-1.5^(e-ENERGY))
*/
rule queen_eats for e in [0, ENERGY-2]{
    Q[e] | N<3> -[ eat_rate * (e/(ENERGY-1))]-> Q[e+2] | N_QF<3>
}

/*
>> QUEEN consume ENERGY <<

Results:
    Drecrease Queen (Q) ENERGY;

Base rates:
    queen_metabolism;
*/
rule queen_consume_energy for e in [1, ENERGY]{
    Q[e] -[queen_metabolism]-> Q[e-1]
}

/* 
>> QUEEN DIES <<

Results:
    Increase Death Queen (DQ);

Base rates: 
    queen_mortality_rate;

Impacts: 
    Number of Workers {WF_1} (Low number of Workers increase queen_mortality_rate);

*/
rule queen_dies for e in [0, ENERGY]{
    Q[e] -[ queen_mortality_rate + 1/4^(#workers - critical_workers_population/2) ]-> DQ
}

/*
>> QUEEN   generate WORKER <<

Results:
    Drecrease Queen ENERGY;
    Increase number of Worker (WB);

Base rates: 
    bee_birth_rate;

Impacts: 
    Food availbility (Low Food decrease bee_birth_rate);
    Number of Worker (High number of Worker decrease bee_birth_rate);
*/
rule queen_generate_worker for e in [1, ENERGY] {
    Q[e] -[ bee_birth_rate * (e/ENERGY) * ((#N+1)/FOOD_STORAGE)]-> Q[e] | WB[ENERGY-1, 0]<2> | BB<2>
}


/* ------------------------------- Worker Bee ------------------------------- */

/*
>> WORKER EATS <<

Results:
    Increase Worker (WB) ENERGY;
    Decrise NECTAR storage (N);

BaseRate:
    eat_rate;

Impacts:
    Residual ENERGY (Low ENERGY increase eat_rate);
*/
rule worker_eat for e in [0, ENERGY-1] and p in [0, POISONING] {
    WB[e,p] | N<1> -[eat_rate * (1 - e/ENERGY)]-> WB[e+1,p] | N_F<1>
}

/*
>> WORKER consume ENERGY <<

Results:
    Decrease Worker (WB) ENERGY;

Base rates:
    worker_metabolism;
*/
rule worker_consume_energy for e in [1, ENERGY] and p in [0, POISONING]{
    WB[e,p] -[worker_metabolism]-> WB[e-1,p]
}

/*
>> WORKER DIES <<

Results:
    Add new entity in Death Worker (DW) species;

Base rates:
    worker_mortality_rate

Impacts:
    Residual ENERGY (Low ENERGY increase worker_mortality_rate);
    POISONING level (High level of POISONING increase worker_mortality_rate);
    Temperature impact {TF_1};
*/
rule worker_dies for e in [0, ENERGY] and p in [0, POISONING] {
    WB[e,p] -[ worker_mortality_rate * (1 - e/ENERGY) + 4^(p - POISONING) + temperature_rate + (1- flowers_biodiversity/SPECIES)/5]-> DW
}

/*
>> WORKER collect NECTAR <<

Results:
    Increase NECTAR storage (N);
    Set FLOWER (F) NECTAR_AVAILABLE to 0;

Base rates:
    worker_store_nectar;

Impacts:
    Food availbility (Low Food increase worker_store_nectar);
    Residual Flowers with NECTAR_AVAILABLE (Low Flowers decrease worker_store_nectar);
*/
rule worker_collect_nectar for e in [1, ENERGY] and p in [0, POISONING] and s in [0, SPECIES]{
    WB[e,p] | F[s,1] -[worker_store_nectar * (1 - #N/FOOD_STORAGE) * (#flowers_nectar_available/#flowers)]-> WB[e,p] | F[s,0] | N<1>
}

/*
>> WORKER is POISONED <<

Results:
    Increase Worker (WB) POISONING;

Base rates:
    pesticide_exposure_rate;
*/
rule worker_exposed_pesticide for e in [0, ENERGY] and p in [0, POISONING-1] {
    WB[e,p] -[pesticide_exposure_rate]-> WB[e,p+1]
}

/*
>> WORKER produce HONEY <<

Results:
    Decrease Nectar storage (N);
    Increase Honey storage (H);

Base rates:
    worker_produce_honey_rate;

Impacts:
    Residual ENERGY (Low ENERGY decrease worker_produce_honey_rate);
    Humidity impact {HF_1};

*/
rule worker_produce_honey for e in [1, ENERGY] and p in [0, POISONING]{
    WB[e,p] | N<2> -[worker_produce_honey_rate * humidity_rate/2 * (e/ENERGY) * (#N/(FOOD_STORAGE))]-> WB[e,p] | H<1> | N_H<2>
}


/* --------------------------------- Flower --------------------------------- */

/*
Flower (F) produce NECTAR:
    NECTAR become AVAILABLE;

Base rates:
    flower_pruduce_nectar_rate

Impacts:
    Param rainfall_rate (Low rainfall decrease flower_pruduce_nectar_rate);
*/
rule flower_produce_nectar for s in [0, SPECIES]{
    F[s,0] -[flower_pruduce_nectar_rate * rainfall_rate]-> F[s,1]
}


/* -------------------------------------------------------------------------- */
/*                            MEASURES & PREDICATE                            */
/* -------------------------------------------------------------------------- */

measure n_bees = #workers;

measure honey_available = #H;
measure nectar_available = #N;
measure flower_with_nectar = #flowers_nectar_available;
measure workers_death = #DW;
measure worker_death_x_born = #DW/#BB;
measure queen_death = #DQ;

/*Debug*/
measure nectar_food = #N_F;
measure nectar_honey = #N_H;
measure nectar_queen_food = #N_QF;

measure born_bee = #BB;

measure poisoned_workers = #infected_workers;


/* -------------------------------- Predicate ------------------------------- */

predicate colony_survived = (#Q[e for e in [0, ENERGY]] > 0);
/* 
predicate honey_decrise = (#HS < 50);
predicate workers = ( #W[i for i in [0,STATES], j for j in [0,ENERGY], z for z in [0,POISONING]]>0);
*/

/* -------------------------------------------------------------------------- */
/*                                   SYSTEM                                   */
/* -------------------------------------------------------------------------- */
system init = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<40> | H<0> | N<40> | F[0,1]<500> | F[1,1]<500>;

system new_hive = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<40>  | H<0> | N<40>             | F[0,1]<500> | F[1,1]<500>;
system old_hive = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<200> | H<0> | N<FOOD_STORAGE/2> | F[0,1]<500> | F[1,1]<500>;

/* ------------------------------- Arid biomes ------------------------------ */

/* 
Desert biome: few flowers, a hot, dry climate and low rainfall;

Params:
    temperature = 45; 
    rainfall_rate = 1;
    humidity = 1;
    flowers_biodiversity = 1 ;
    pesticide_exposure_rate = 0.0; 0.8;
*/
system new_hive_desert = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<40>  | H<0> | N<40>             | F[0,1]<10>;
system old_hive_desert = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<200> | H<0> | N<FOOD_STORAGE/2> | F[0,1]<10>;

/*
Savanna biome: 

Params:
    temperature = 31; 
    rainfall_rate = 1;
    humidity = 1;
    flowers_biodiversity = 1 ;
    pesticide_exposure_rate = 0.0; 0.8;
*/
system new_hive_savanna = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<40>  | H<0> | N<40>             | F[0,1]<300>;
system old_hive_savanna = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<200> | H<0> | N<FOOD_STORAGE/2> | F[0,1]<300>;

/*
Taiga biome: 

Params:
    temperature = 15; 
    rainfall_rate = 1;
    humidity = 1;
    flowers_biodiversity = 1 ;
    pesticide_exposure_rate = 0.0; 0.8;
*/
system new_hive_taiga = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<40>  | H<0> | N<40>             | F[0,1]<400>;
system old_hive_taiga = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<200> | H<0> | N<FOOD_STORAGE/2> | F[0,1]<400>;

/* ----------------------------- Wetland biomes ----------------------------- */

/*
Jungle biome: 

Params:
    temperature = 45; 
    rainfall_rate = 1;
    humidity = 9;
    flowers_biodiversity = 3 ;
    pesticide_exposure_rate = 0.0; 0.8;
*/
system new_hive_jungle = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<40>  | H<0> | N<40>             | F[0,1]<300> | F[1,1]<300> | F[2,1]<300>;
system old_hive_jungle = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<200> | H<0> | N<FOOD_STORAGE/2> | F[0,1]<300> | F[1,1]<300> | F[2,1]<300>;

/*
Swamp biome: 

Params:
    temperature = 31; 
    rainfall_rate = 1;
    humidity = 9;
    flowers_biodiversity = 3 ;
    pesticide_exposure_rate = 0.0; 0.8;
*/
system new_hive_swamp = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<40>  | H<0> | N<40>             | F[0,1]<200> | F[1,1]<200> | F[2,1]<200>;
system old_hive_swamp = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<200> | H<0> | N<FOOD_STORAGE/2> | F[0,1]<200> | F[1,1]<200> | F[2,1]<200>;

/*
Frozen River biome: 

Params:
    temperature = 15; 
    rainfall_rate = 1;
    humidity = 9;
    flowers_biodiversity = 3 ;
    pesticide_exposure_rate = 0.0; 0.8;
*/
system new_hive_frozen_river = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<40>  | H<0> | N<40>             | F[0,1]<200> | F[2,1]<200> | F[2,1]<200>;
system old_hive_frozen_river = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<200> | H<0> | N<FOOD_STORAGE/2> | F[0,1]<200> | F[2,1]<200> | F[2,1]<200>;

/* ---------------------------- Temperate biomes ---------------------------- */

/*
Plains biome: 

Params:
    temperature = 45; 
    rainfall_rate = 1;
    humidity = 5;
    flowers_biodiversity = 2 ;
    pesticide_exposure_rate = 0.0; 0.8;
*/
system new_hive_plains = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<40>  | H<0> | N<40>             | F[0,1]<400> | F[1,1]<400>;
system old_hive_plains = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<200> | H<0> | N<FOOD_STORAGE/2> | F[0,1]<400> | F[1,1]<400>;

/*
Flower Forest biome: 

Params:
    temperature = 31; 
    rainfall_rate = 1;
    humidity = 5;
    flowers_biodiversity = 2 ;
    pesticide_exposure_rate = 0.0; 0.8;
*/
system new_hive_flower_forest = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<40>  | H<0> | N<40>             | F[0,1]<600> | F[1,1]<600>;
system old_hive_flower_forest = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<200> | H<0> | N<FOOD_STORAGE/2> | F[0,1]<600> | F[1,1]<600>;

/*
Stony Peaks biome: 

Params:
    temperature = 15; 
    rainfall_rate = 1;
    humidity = 5;
    flowers_biodiversity = 2 ;
    pesticide_exposure_rate = 0.0; 0.8;
*/
system new_hive_stony_peaks = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<40>  | H<0> | N<40>             | F[0,1]<250> | F[2,1]<250>;
system old_hive_stony_peaks = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<200> | H<0> | N<FOOD_STORAGE/2> | F[0,1]<250> | F[2,1]<250>;

/* ------------------------------ Mixed biomes ------------------------------ */

/*
Desert x Flower Forest biome: 

Params:
    temperature = 45; 
    rainfall_rate = 0.3;
    humidity = 1;
    flowers_biodiversity = 2 ;
    pesticide_exposure_rate = 0.0; 0.8;
*/
system new_hive_desert_x_flower_forest = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<40>  | H<0> | N<40>             | F[0,1]<600> | F[1,1]<600>;
system old_hive_desert_x_flower_forest = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<200> | H<0> | N<FOOD_STORAGE/2> | F[0,1]<600> | F[1,1]<600>;

/*
Flower Forest x Desert biome: 

Params:
    temperature = 31; 
    rainfall_rate = 1;
    humidity = 5;
    flowers_biodiversity = 1 ;
    pesticide_exposure_rate = 0.0; 0.8;
*/
system new_hive_flower_forest_x_desert = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<40>  | H<0> | N<40>             | F[0,1]<10>;
system old_hive_flower_forest_x_desert = Q[ENERGY-1]<1> | WB[ENERGY-1, 0]<200> | H<0> | N<FOOD_STORAGE/2> | F[0,1]<10>;


/* -------------------------------------------------------------------------- */
/*                                TODO & NOTES                                */
/* -------------------------------------------------------------------------- */

/* 
NOTES:

------------------------------------ - -----------------------------------
Worker (WS) store NECTAR (N):
    Decrease bee ENERGY;
    Increase NECTAR storage (N);

Base rates:
    worker_store_nectar;


rule worker_store_nectar for e in [1, ENERGY] and p in [0, POISONING] {
    WB[e,p] -[worker_store_nectar * (1- #used_storage/food_storage)]-> WB[e,p] | N<1>
}
------------------------------------ - -----------------------------------

*/

/*
TODO: 
    Possible simulation: Pesticidi?? Temperature intermedie (caldo-normale e normale-freddo)??
*/