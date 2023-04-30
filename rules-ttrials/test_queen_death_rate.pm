
/* ---------------------------------- Const --------------------------------- */

const ENERGY = 10;                          /* The energy available to a bee */

const queen_mortality_rate = 0.001;
const critical_workers_population = 10;

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
    Q[e] -[ (queen_mortality_rate) + 1/4^((workers + 1) - critical_workers_population/3)]-> DQ
}

/* -------------------------------------------------------------------------- */
/*                                   MEASURE                                  */
/* -------------------------------------------------------------------------- */

measure queen_death = #Q[e for e in [0,ENERGY]];

/* -------------------------------------------------------------------------- */
/*                                   SYSTEM                                   */
/* -------------------------------------------------------------------------- */

system init = Q[0]<1>;