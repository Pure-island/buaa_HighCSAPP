/*
 * Generated by Bluespec Compiler, version 2019.05.beta2 (build a88bf40, 2019-05-24)
 * 
 * On Fri Jun 23 17:04:36 CST 2023
 * 
 */
#include "bluesim_primitives.h"
#include "model_mkTests.h"

#include <cstdlib>
#include <time.h>
#include "bluesim_kernel_api.h"
#include "bs_vcd.h"
#include "bs_reset.h"


/* Constructor */
MODEL_mkTests::MODEL_mkTests()
{
  mkTests_instance = NULL;
}

/* Function for creating a new model */
void * new_MODEL_mkTests()
{
  MODEL_mkTests *model = new MODEL_mkTests();
  return (void *)(model);
}

/* Schedule functions */

static void schedule_posedge_CLK(tSimStateHdl simHdl, void *instance_ptr)
       {
	 MOD_mkTests &INST_top = *((MOD_mkTests *)(instance_ptr));
	 INST_top.DEF_CAN_FIRE_RL_test = (tUInt8)1u;
	 INST_top.DEF_WILL_FIRE_RL_test = INST_top.DEF_CAN_FIRE_RL_test;
	 if (INST_top.DEF_WILL_FIRE_RL_test)
	   INST_top.RL_test();
	 if (do_reset_ticks(simHdl))
	 {
	 }
       };

/* Model creation/destruction functions */

void MODEL_mkTests::create_model(tSimStateHdl simHdl, bool master)
{
  sim_hdl = simHdl;
  init_reset_request_counters(sim_hdl);
  mkTests_instance = new MOD_mkTests(sim_hdl, "top", NULL);
  bk_get_or_define_clock(sim_hdl, "CLK");
  if (master)
  {
    bk_alter_clock(sim_hdl, bk_get_clock_by_name(sim_hdl, "CLK"), CLK_LOW, false, 0llu, 5llu, 5llu);
    bk_use_default_reset(sim_hdl);
  }
  bk_set_clock_event_fn(sim_hdl,
			bk_get_clock_by_name(sim_hdl, "CLK"),
			schedule_posedge_CLK,
			NULL,
			(tEdgeDirection)(POSEDGE));
  (mkTests_instance->set_clk_0)("CLK");
}
void MODEL_mkTests::destroy_model()
{
  delete mkTests_instance;
  mkTests_instance = NULL;
}
void MODEL_mkTests::reset_model(bool asserted)
{
  (mkTests_instance->reset_RST_N)(asserted ? (tUInt8)0u : (tUInt8)1u);
}
void * MODEL_mkTests::get_instance()
{
  return mkTests_instance;
}

/* Fill in version numbers */
void MODEL_mkTests::get_version(unsigned int *year,
				unsigned int *month,
				char const **annotation,
				char const **build)
{
  *year = 2019u;
  *month = 5u;
  *annotation = "beta2";
  *build = "a88bf40";
}

/* Get the model creation time */
time_t MODEL_mkTests::get_creation_time()
{
  
  /* Fri Jun 23 09:04:36 UTC 2023 */
  return 1687511076llu;
}

/* Control run-time licensing */
tUInt64 MODEL_mkTests::skip_license_check()
{
  return 0llu;
}

/* State dumping function */
void MODEL_mkTests::dump_state()
{
  (mkTests_instance->dump_state)(0u);
}

/* VCD dumping functions */
MOD_mkTests & mkTests_backing(tSimStateHdl simHdl)
{
  static MOD_mkTests *instance = NULL;
  if (instance == NULL)
  {
    vcd_set_backing_instance(simHdl, true);
    instance = new MOD_mkTests(simHdl, "top", NULL);
    vcd_set_backing_instance(simHdl, false);
  }
  return *instance;
}
void MODEL_mkTests::dump_VCD_defs()
{
  (mkTests_instance->dump_VCD_defs)(vcd_depth(sim_hdl));
}
void MODEL_mkTests::dump_VCD(tVCDDumpType dt)
{
  (mkTests_instance->dump_VCD)(dt, vcd_depth(sim_hdl), mkTests_backing(sim_hdl));
}
