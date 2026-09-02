
aimc-en2 - aimc-ven4: GRID V100DX-8Q profile 
 
NVIDIA-SMI 525.85.05    Driver Version: 525.85.05    CUDA Version: 12.0


aimc-en1 aimc-ven2 - GRID V100DX-16Q profile
NVIDIA-SMI 525.85.05    Driver Version: 525.85.05    CUDA Version: 12.0


python -c "import torch; print(torch.__version__)"
2.1.1+cu118


Issue:
[383305.697956] FS-Cache: Duplicate cookie detected
[383305.699193] FS-Cache: O-cookie c=00000003 [p=00000002 fl=222 nc=0 na=1]
[383305.700775] FS-Cache: O-cookie d=0000000022f4a5d4{NFS.server} n=00000000915dd700
[383305.702484] FS-Cache: O-key=[16] '040000000200000002000801ac10000f'
[383305.703753] FS-Cache: N-cookie c=00000005 [p=00000002 fl=2 nc=0 na=1]
[383305.704974] FS-Cache: N-cookie d=0000000022f4a5d4{NFS.server} n=0000000021a37ea3
[383305.706389] FS-Cache: N-key=[16] '040000000200000002000801ac10000f'

TODO:
Check CUDA + torch version
Check image version
Check deployment


Fix NVIDIA driver cannot communicate
sudo dkms remove nvidia/460.39 --all
sudo dkms install --force nvidia/460.39 -k $(uname -r)
sudo update-initramfs -u



