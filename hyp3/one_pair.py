# simple test case

#mamba create --name hyp3_sdk  -c conda-forge hyp3_sdk --yes
# mamba activate hyp3_sdk
# python /Users/feigl/FringeFlow/hyp3/one_pair.py 

#import asf_search as asf
import hyp3_sdk as sdk

hyp3 = sdk.HyP3(prompt=False)
nCredits0 = hyp3.check_credits()
print(f'nCredits0 = {nCredits0}')
looks='10x2'
jobs = sdk.Batch()
epoch0='S1_135553_IW2_20200926T015127_VV_96EE-BURST'
epoch1='S1_135553_IW2_20201008T015127_VV_0BD2-BURST'     
jobs+=hyp3.submit_insar_isce_burst_job(epoch0, epoch1, 
    name='one_pair', 
    apply_water_mask=True,
    looks=looks)
