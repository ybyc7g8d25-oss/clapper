/* Весь звук синтезируется через WebAudio — никаких файлов и лицензий. */
const sfx=(()=>{
  let ctx=null, master=null, amb=null, on=true, dr=null, drLevel=0, stageNow=0;
  const c=()=>{
    if(!ctx){ try{
      ctx=new (window.AudioContext||window.webkitAudioContext)();
      master=ctx.createGain(); master.connect(ctx.destination);
      amb=ctx.createGain(); amb.connect(master);
      master.gain.value=Settings.vol; amb.gain.value=Settings.amb;
    }catch(e){} }
    return ctx;
  };
  function tone(f,d,type='sine',v=.05,when=0,dest){
    const a=c(); if(!a||!on) return;
    const t=a.currentTime+when, o=a.createOscillator(), g=a.createGain();
    o.type=type; o.frequency.value=f;
    g.gain.setValueAtTime(0,t); g.gain.linearRampToValueAtTime(v,t+.01); g.gain.exponentialRampToValueAtTime(.0001,t+d);
    o.connect(g).connect(dest||master); o.start(t); o.stop(t+d+.05);
  }
  function noise(dur,freq,v,q=1){
    const a=c(); if(!a||!on) return;
    const len=Math.floor(a.sampleRate*dur), b=a.createBuffer(1,len,a.sampleRate), d=b.getChannelData(0);
    for(let i=0;i<len;i++) d[i]=(Math.random()*2-1)*(1-i/len);
    const s=a.createBufferSource(); s.buffer=b;
    const f=a.createBiquadFilter(); f.type='bandpass'; f.frequency.value=freq; f.Q.value=q;
    const g=a.createGain(); g.gain.value=v;
    s.connect(f).connect(g).connect(master); s.start();
  }
  return {
    resume(){ const a=c(); if(a&&a.state==='suspended') a.resume(); },
    setVolume(v,a){ if(master){ master.gain.value=v; amb.gain.value=a; } },
    chime(){[523,659,784,1046].forEach((f,i)=>tone(f,.55,'triangle',.06,i*.13))},
    sadChime(){[784,659,523,392].forEach((f,i)=>tone(f,.8,'triangle',.05,i*.35))},
    softChime(){[392,523,659].forEach((f,i)=>tone(f,1.2,'sine',.04,i*.5))},
    click(){tone(1500,.025,'square',.012)},
    tick(){const s=state.stage; tone(s>=3?170+Math.random()*30:(s>=2?420:880+Math.random()*140),.022,'square',.007)},
    key(){tone(2200+Math.random()*400,.015,'square',.006)},
    err(){tone(230,.18,'square',.035); tone(160,.28,'square',.035,.16)},
    msg(){tone(990,.08,'sine',.05); tone(1320,.12,'sine',.05,.09)},
    shard(){[1318,1760,2093].forEach((f,i)=>tone(f,.9,'sine',.035,i*.09))},
    glitch(){ noise(.18,700+Math.random()*2200,.14); },
    scare(){ noise(.6,300,.5,.5); tone(62,.7,'sawtooth',.2); tone(1900,.5,'square',.05); },
    door(v=1){ noise(.25,160,.5*v,2); tone(70,.3,'sine',.15*v,.02); },
    step(v=1){ noise(.09,120,.35*v,3); tone(48,.12,'sine',.12*v); },
    heart(){ tone(55,.14,'sine',.16); tone(50,.16,'sine',.12,.2); },
    drone(n){
      stageNow=n;
      const a=c(); if(!a) return;
      if(!dr){
        const g=a.createGain(); g.gain.value=0; g.connect(amb);
        const lp=a.createBiquadFilter(); lp.type='lowpass'; lp.frequency.value=200; lp.connect(g);
        const o1=a.createOscillator(), o2=a.createOscillator(), o3=a.createOscillator();
        o1.type='sawtooth'; o1.frequency.value=55; o2.type='sine'; o2.frequency.value=58.2; o3.type='sine'; o3.frequency.value=110.6;
        [o1,o2,o3].forEach(o=>{ o.connect(lp); o.start(); }); dr=g;
      }
      drLevel=on?([.002,.008,.024,.048][n]||0):0;
      dr.gain.setTargetAtTime(drLevel,a.currentTime,2);
    },
    duck(p){ const a=c(); if(a&&dr) dr.gain.setTargetAtTime(p?0:drLevel,a.currentTime,.3); },
    toggle(){ on=!on; this.drone(stageNow); return on; },
    get on(){ return on; }
  };
})();
