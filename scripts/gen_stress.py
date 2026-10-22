"""Cycle oracle for the repository's request/response memory, not DDR PHY."""
from pathlib import Path
import random

def main():
    rng=random.Random(20261022); mem=[0]*256; pending=None; rows=[]
    for t in range(2200):
        rst=int(t in (0,1,999,1000))
        valid=int(t<2198 and t%11!=0)
        write=int(t%3==0)
        addr=t%256 if t<800 else rng.randrange(256)
        data=rng.getrandbits(32)
        if rst:
            mem=[0]*256; pending=None; ev=0; ed=0
        else:
            ev=int(pending is not None); ed=mem[pending] if ev else 0
            pending=None
            if valid:
                if write: mem[addr]=data
                else: pending=addr
        rows.append((rst,valid,write,addr,data,ev,ed))
    Path('build').mkdir(exist_ok=True)
    Path('build/stress.txt').write_text('\n'.join(' '.join(f'{v:x}' for v in row) for row in rows)+'\n')
    print(f'Oracle: {len(rows)} cycles, seed=20261022')

if __name__=='__main__': main()
