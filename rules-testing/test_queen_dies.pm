
/* ---------------------------------- Const --------------------------------- */

const ENERGY = 10;                          /* The energy available to a bee */
const QUEEN_LIFE = 800;                     /* On average, a queen lives about 2 years */

const time_multipliers = 6;
const queen_mortality_rate = 1/(queen_life * time_multipliers);
const critical_workers_population = 5;

/* --------------------------------- Agents --------------------------------- */

species Q of [0, ENERGY];                               /* Queen */
species DQ;                                             /* Death Queen */

/* --------------------------------- Params --------------------------------- */

param workers = 5;

/* ---------------------------------- Rules --------------------------------- */

/* 
Queen dies:

Base rates: 
    queen_mortality_rate;

Impacts: 
    Number of Worker (Low number of Worker increase queen_mortality_rate);

*/
rule queen_dies for e in [0, ENERGY]{
    Q[e] -[ (queen_mortality_rate) + 1/4^(workers - critical_workers_population/3)]-> DQ
}

/* -------------------------------------------------------------------------- */
/*                                   MEASURE                                  */
/* -------------------------------------------------------------------------- */

measure queen_death = #Q[0];

/* -------------------------------------------------------------------------- */
/*                                   SYSTEM                                   */
/* -------------------------------------------------------------------------- */

system init = Q[0]<1>;