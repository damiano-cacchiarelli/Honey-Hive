const ENERGY = 10;                                      /* The energy available to a bee. A bee with 0 energy cannot perform activities */
const POISONING = 10;                                   /* The poisoning level of a bee */


species WB of [0, ENERGY]*[0, POISONING];               /* Worker Bee, perform activities in the hive */
species FB of [0, ENERGY]*[0, POISONING];               /* Forager Bee, seeks nectar outside the hive */

species N;                                              /* Nectar Storage */

const food_storage = 1000;                              /* The amount of nectar that can be stored */
const changeOfWorkRate      = 0.5;

label workers = { WB[e, p for e in [1,ENERGY] and p in [0,POISONING]] }
label foragers = { FB[e, p for e in [1,ENERGY] and p in [0,POISONING]] }
label worker_bees = {
    WB[e, p for e in [1,ENERGY] and p in [0,POISONING]],
    FB[e, p for e in [1,ENERGY] and p in [0,POISONING]]
}

rule forager_become_worker for e in [0, ENERGY] and p in [0, POISONING-1] {
    FB[e,p] -[changeOfWorkRate * (1/1.5^(x*10/food_storage)) * (#workers/#worker_bees)^4]-> WB[e,p]
}

rule worker_become_forager for e in [0, ENERGY] and p in [0, POISONING-1] {
    WB[e,p] -[changeOfWorkRate * (1 - 1/1.5^(x*10/food_storage)) * (#foragers/#worker_bees)^4]-> FB[e,p]
}

measure workers = #workers;
measure forages = #foragers;

system init = WB[ENERGY-1, 0]<10> | FB[ENERGY-1, 0]<90> | N<900>;