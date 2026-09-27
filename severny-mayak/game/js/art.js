/* Графика: значки Nimbus 2004 и детские рисунки мелком (SVG). */
const ICON={
  note:`<svg viewBox="0 0 32 32"><path d="M6 2h14l6 6v22H6z" fill="#fff" stroke="#44506a" stroke-width="1.5"/><path d="M20 2v6h6" fill="#dfe6f2" stroke="#44506a" stroke-width="1.5"/><path d="M10 13h12M10 17h12M10 21h9M10 25h11" stroke="#7d8aa6" stroke-width="1.5"/></svg>`,
  noteRed:`<svg viewBox="0 0 32 32"><path d="M6 2h14l6 6v22H6z" fill="#fff" stroke="#7a1510" stroke-width="1.5"/><path d="M20 2v6h6" fill="#f3d6d4" stroke="#7a1510" stroke-width="1.5"/><path d="M10 13h12M10 17h12M10 21h9" stroke="#c9372f" stroke-width="1.5"/><text x="16" y="29" font-size="7" text-anchor="middle" fill="#c9372f" font-family="monospace">!</text></svg>`,
  folder:`<svg viewBox="0 0 32 32"><path d="M2 8h11l3 3h14v17H2z" fill="#f6c343" stroke="#a87b0b" stroke-width="1.5"/><path d="M2 13h28v15H2z" fill="#ffd966" stroke="#a87b0b" stroke-width="1.5"/></svg>`,
  pixel:`<svg viewBox="0 0 32 32"><path d="M16 2v5" stroke="#1d1a2b" stroke-width="2"/><circle cx="16" cy="3" r="2.5" fill="#ff6b6b"/><rect x="4" y="7" width="24" height="21" rx="4" fill="#9fd8ff" stroke="#1d1a2b" stroke-width="2"/><rect x="10" y="13" width="3" height="4" fill="#1d1a2b"/><rect x="19" y="13" width="3" height="4" fill="#1d1a2b"/><path d="M11 21q5 4 10 0" stroke="#1d1a2b" stroke-width="2" fill="none"/></svg>`,
  web:`<svg viewBox="0 0 32 32"><circle cx="16" cy="16" r="13" fill="#5fb4f0" stroke="#1e5d99" stroke-width="1.5"/><path d="M16 3v26M3 16h26M6 7l20 18M26 7L6 25" stroke="#fff" stroke-width="1.2" opacity=".85"/><circle cx="16" cy="16" r="5" fill="none" stroke="#fff" stroke-width="1.2"/><circle cx="16" cy="16" r="9" fill="none" stroke="#fff" stroke-width="1.2"/></svg>`,
  mail:`<svg viewBox="0 0 32 32"><rect x="3" y="8" width="26" height="18" rx="2" fill="#fff" stroke="#3a4358" stroke-width="1.5"/><path d="M3 9l13 10 13-10" fill="none" stroke="#3a4358" stroke-width="1.5"/><path d="M20 4q4-3 8 0q-4 1-4 5q-2-3-4-5z" fill="#9aa7bd" stroke="#3a4358" stroke-width="1"/></svg>`,
  tale:`<svg viewBox="0 0 32 32"><path d="M3 6q7-3 13 1v21q-6-4-13-1z" fill="#fff6d6" stroke="#6b5a1d" stroke-width="1.5"/><path d="M29 6q-7-3-13 1v21q6-4 13-1z" fill="#fff" stroke="#6b5a1d" stroke-width="1.5"/><path d="M21 22l2-10h3l2 10z" fill="#e2574c"/><circle cx="24.5" cy="11" r="1.8" fill="#f2c94c"/></svg>`,
  diary:`<svg viewBox="0 0 32 32"><rect x="5" y="3" width="20" height="26" rx="2" fill="#d9534f" stroke="#7a1f1c" stroke-width="1.5"/><path d="M8 3v26" stroke="#7a1f1c" stroke-width="1.5"/><rect x="16" y="17" width="12" height="10" rx="1.5" fill="#f2c94c" stroke="#8a6a00" stroke-width="1.5"/><path d="M18.5 17v-3a3.5 3.5 0 0 1 7 0v3" fill="none" stroke="#8a6a00" stroke-width="1.8"/></svg>`,
  cam:`<svg viewBox="0 0 32 32"><circle cx="16" cy="13" r="10" fill="#e9edf3" stroke="#3a4358" stroke-width="1.5"/><circle cx="16" cy="13" r="5.5" fill="#1d2232"/><circle cx="14" cy="11" r="1.6" fill="#8fb8ff"/><path d="M11 23l-3 6h16l-3-6" fill="#c9d0db" stroke="#3a4358" stroke-width="1.5"/></svg>`,
  chat:`<svg viewBox="0 0 32 32"><path d="M4 6h24v16H13l-6 6v-6H4z" fill="#6fd06b" stroke="#2e7d32" stroke-width="1.5"/><circle cx="11" cy="14" r="1.8" fill="#fff"/><circle cx="16" cy="14" r="1.8" fill="#fff"/><circle cx="21" cy="14" r="1.8" fill="#fff"/></svg>`,
  bin:`<svg viewBox="0 0 32 32"><path d="M7 9h18l-2 20H9z" fill="#d6dde8" stroke="#4b5870" stroke-width="1.5"/><path d="M5 9h22" stroke="#4b5870" stroke-width="2"/><path d="M10 6l6-3 7 4" fill="#fff" stroke="#4b5870" stroke-width="1.2"/><path d="M12 13v12M16 13v12M20 13v12" stroke="#8b97ab" stroke-width="1.3"/></svg>`,
  tm:`<svg viewBox="0 0 32 32"><rect x="3" y="5" width="26" height="20" rx="2" fill="#1d2232" stroke="#3a4358" stroke-width="1.5"/><path d="M6 19l5-6 4 4 5-8 4 5 3-2" fill="none" stroke="#46c24a" stroke-width="2"/><path d="M11 29h10M16 25v4" stroke="#3a4358" stroke-width="2"/></svg>`,
  warn:`<svg viewBox="0 0 32 32"><path d="M16 3L30 28H2z" fill="#f2c94c" stroke="#7a5a00" stroke-width="1.5"/><path d="M16 11v9" stroke="#1d1a2b" stroke-width="3"/><circle cx="16" cy="24" r="1.8" fill="#1d1a2b"/></svg>`,
  stop:`<svg viewBox="0 0 32 32"><circle cx="16" cy="16" r="13" fill="#e0493f" stroke="#7a1510" stroke-width="1.5"/><path d="M10 10l12 12M22 10L10 22" stroke="#fff" stroke-width="3"/></svg>`,
  info:`<svg viewBox="0 0 32 32"><circle cx="16" cy="16" r="13" fill="#5fb4f0" stroke="#1e5d99" stroke-width="1.5"/><path d="M16 14v9" stroke="#fff" stroke-width="3"/><circle cx="16" cy="9.5" r="2" fill="#fff"/></svg>`,
  power:`<svg viewBox="0 0 32 32"><rect x="3" y="3" width="26" height="26" rx="5" fill="#e0493f" stroke="#7a1510" stroke-width="1.5"/><path d="M16 8v8" stroke="#fff" stroke-width="3"/><path d="M11 11a7 7 0 1 0 10 0" fill="none" stroke="#fff" stroke-width="2.5"/></svg>`,
  gear:`<svg viewBox="0 0 32 32"><circle cx="16" cy="16" r="9" fill="#c9d0db" stroke="#3a4358" stroke-width="2" stroke-dasharray="4 2.3"/><circle cx="16" cy="16" r="4" fill="#fff" stroke="#3a4358" stroke-width="1.5"/></svg>`,
  cloud:`<svg viewBox="0 0 32 32"><path d="M8 26h17a6 6 0 0 0 1-12 8 8 0 0 0-15-2 6.5 6.5 0 0 0-3 14z" fill="#fff"/></svg>`,
  spk:`<svg viewBox="0 0 16 16"><path d="M2 6h3l4-3v10L5 10H2z" fill="#fff"/><path d="M11 5a4 4 0 0 1 0 6M12.5 3.5a6 6 0 0 1 0 9" stroke="#fff" fill="none" stroke-width="1.3"/></svg>`,
  mute:`<svg viewBox="0 0 16 16"><path d="M2 6h3l4-3v10L5 10H2z" fill="#fff"/><path d="M11 6l4 4M15 6l-4 4" stroke="#fff" stroke-width="1.4"/></svg>`,
  star:`<svg viewBox="0 0 16 16"><path d="M8 1l2 5 5 .5-4 3.5 1.3 5L8 12.3 3.7 15 5 10 1 6.5 6 6z" fill="#ffe96b" stroke="#a87b0b"/></svg>`
};

function avatarSVG(s,big){
  const ink='#1d1a2b';
  const eyes = s===0 ? `<path d="M20 30q5-6 10 0M38 30q5-6 10 0" stroke="${ink}" stroke-width="3" fill="none" stroke-linecap="round"/>`
    : s===3 ? `<rect x="22" y="26" width="6" height="6" fill="#ff3b30"/><rect x="40" y="26" width="6" height="6" fill="#ff3b30"/>`
    : `<rect x="22" y="25" width="6" height="7" fill="${ink}"/><rect x="40" y="25" width="6" height="7" fill="${ink}"/>`;
  const mouth = big ? `<path d="M22 42h24v8H22z" fill="#ff3b30"/><path d="M25 42v8M29 42v8M33 42v8M37 42v8M41 42v8" stroke="#141018" stroke-width="1.5"/>`
    : s===0 ? `<path d="M24 42q10 8 20 0" stroke="${ink}" stroke-width="3" fill="none" stroke-linecap="round"/>`
    : s===1 ? `<path d="M26 44q8 3 16 0" stroke="${ink}" stroke-width="3" fill="none" stroke-linecap="round"/>`
    : s===2 ? `<path d="M26 45h16" stroke="${ink}" stroke-width="3" stroke-linecap="round"/>` : '';
  const face = s===3?'#141018':(s===2?'#b9cbd6':'#9fd8ff');
  return `<svg viewBox="0 0 68 68" aria-hidden="true"><line x1="34" y1="3" x2="34" y2="12" stroke="${ink}" stroke-width="3"/><circle cx="34" cy="5" r="4" fill="${s===3?'#ff3b30':'#ff6b6b'}"/><rect x="8" y="12" width="52" height="46" rx="9" fill="${face}" stroke="${s===3?'#ff3b30':ink}" stroke-width="3"/>${eyes}${mouth}</svg>`;
}

const crayon=(id,seed,scale=6)=>`<filter id="${id}"><feTurbulence type="fractalNoise" baseFrequency=".035" numOctaves="2" seed="${seed}"/><feDisplacementMap in="SourceGraphic" scale="${scale}"/></filter>`;

function wallSVG(p){
  return `<svg viewBox="0 0 1200 800" preserveAspectRatio="xMidYMid slice" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
<defs>${crayon(p+'cr',4,7)}
<radialGradient id="${p}gl"><stop offset="0" stop-color="#fff6a0" stop-opacity=".95"/><stop offset="1" stop-color="#fff6a0" stop-opacity="0"/></radialGradient></defs>
<rect width="1200" height="800" fill="#bfe4ff"/>
<g filter="url(#${p}cr)" stroke-linecap="round" stroke-linejoin="round">
 <g class="wp-sun"><circle cx="170" cy="150" r="66" fill="#ffd23f" stroke="#e39b00" stroke-width="6"/>
  <path d="M170 50v-30M170 250v30M70 150h-30M270 150h30M100 80l-22-22M240 80l22-22M100 220l-22 22M240 220l22 22" stroke="#e39b00" stroke-width="7"/></g>
 <path d="M430 150q20-40 60-20q30-35 70 0q40-5 35 30q-10 25-50 20h-95q-40-5-20-30z" fill="#fff" stroke="#9cc3e0" stroke-width="5"/>
 <path d="M0 560Q260 470 560 540T1200 500L1200 800L0 800Z" fill="#86d36f" stroke="#4f9e3d" stroke-width="6"/>
 <path d="M760 800C820 720 1000 700 1200 640L1200 800Z" fill="#5aa9e6" stroke="#2f78b8" stroke-width="5"/>
 <path d="M840 770q20-10 40 0M960 730q20-10 40 0M1080 700q20-10 40 0" stroke="#fff" stroke-width="4" fill="none"/>
 <circle class="wp-glow" cx="970" cy="275" r="130" fill="url(#${p}gl)"/>
 <path d="M925 560L945 300L995 300L1015 560Z" fill="#efe9df" stroke="#555" stroke-width="6"/>
 <path d="M933 470L1007 470L1010 505L930 505Z" fill="#e2574c"/><path d="M940 380L1000 380L1003 415L937 415Z" fill="#e2574c"/>
 <rect x="935" y="250" width="70" height="50" fill="#3a3f55" stroke="#555" stroke-width="6"/>
 <path d="M925 250L970 205L1015 250Z" fill="#e2574c" stroke="#555" stroke-width="6"/>
 <circle class="wp-light" cx="970" cy="275" r="17" fill="#fff27a"/>
 <path d="M880 205q30 10 45 40" stroke="#3a2f8f" stroke-width="5" fill="none"/><path d="M912 232l13 13l2-18" stroke="#3a2f8f" stroke-width="5" fill="none"/>
 <g class="wp-boy">
  <path d="M390 440L450 440L464 532L376 532Z" fill="#2b6fd6" stroke="#1b4c99" stroke-width="5"/>
  <path d="M398 532l-10 70M442 532l10 70" stroke="#333" stroke-width="9"/>
  <path d="M390 452l-42 50M450 452l58 44" stroke="#ffcfa5" stroke-width="10"/>
  <circle cx="420" cy="400" r="36" fill="#ffe0c2" stroke="#8a5a33" stroke-width="5"/>
  <path d="M386 392q10-40 38-38q28-2 34 30q-18-14-36-8q-18-10-36 16z" fill="#7a4a22"/>
  <circle cx="408" cy="404" r="4" fill="#222"/><circle cx="433" cy="404" r="4" fill="#222"/>
  <path d="M407 418q13 11 26 0" stroke="#222" stroke-width="4" fill="none"/>
 </g>
 <g class="wp-bot">
  <path d="M555 410v-26" stroke="#1d1a2b" stroke-width="5"/><circle cx="555" cy="378" r="9" fill="#ff6b6b" stroke="#1d1a2b" stroke-width="4"/>
  <rect x="515" y="410" width="80" height="64" rx="11" fill="#8fd0ff" stroke="#2d5f8a" stroke-width="6"/>
  <circle cx="540" cy="438" r="7" fill="#1d1a2b"/><circle cx="572" cy="438" r="7" fill="#1d1a2b"/>
  <path d="M537 455q18 14 36 0" stroke="#1d1a2b" stroke-width="5" fill="none"/>
  <rect x="527" y="478" width="56" height="60" rx="6" fill="#c8b8ff" stroke="#5a3db8" stroke-width="6"/>
  <path d="M527 496l-20 0M541 538v62M569 538v62M583 496l22 12" stroke="#1d1a2b" stroke-width="7"/>
 </g>
 <path d="M660 360q-12-16-24 0q-12 16 24 34q36-18 24-34q-12-16-24 0z" fill="#ff7aa2" stroke="#c23d6a" stroke-width="4"/>
</g>
<text x="355" y="705" font-family="Caveat, Comic Sans MS, cursive" font-size="74" fill="#3a2f8f">${esc(L.art.wallMe)}</text>
<text x="690" y="178" font-family="Caveat, Comic Sans MS, cursive" font-size="40" fill="#3a2f8f">${esc(L.art.wallLives)}</text>
<path class="wp-scratch" d="M345 690l60-32l-52 42l72-34l-62 40l70-30l-66 38" fill="none" stroke="#141414" stroke-width="10" stroke-linecap="round"/>
</svg>`;
}

function towerSVG(){
  return `<svg viewBox="0 0 600 420" xmlns="http://www.w3.org/2000/svg"><defs>${crayon('tcr',9,5)}</defs>
<rect width="600" height="420" fill="#1c2a5a"/>
<g filter="url(#tcr)" stroke-linecap="round" stroke-linejoin="round">
<path d="M60 50l4 8l9 1l-7 6l2 9l-8-5l-8 5l2-9l-7-6l9-1z M500 40l3 6l7 1l-5 4l1 7l-6-4l-6 4l1-7l-5-4l7-1z M140 120l3 6l7 1l-5 4l1 7l-6-4l-6 4l1-7l-5-4l7-1z M430 150l3 6l7 1l-5 4l1 7l-6-4l-6 4l1-7l-5-4l7-1z" fill="#ffe96b"/>
<path d="M300 110L600 40L600 150Z M300 110L0 60L0 170Z" fill="#fff27a" opacity=".35"/>
<path d="M0 330q150-30 300-10t300-10v110H0z" fill="#2f78b8" stroke="#8fc3f0" stroke-width="4"/>
<path d="M260 350L278 120L322 120L340 350Z" fill="#efe9df" stroke="#333" stroke-width="5"/>
<path d="M266 280h68l3 30h-74zM271 190h58l3 30h-64z" fill="#e2574c"/>
<rect x="270" y="80" width="60" height="42" fill="#fff27a" stroke="#333" stroke-width="5"/>
<path d="M262 80L300 46L338 80Z" fill="#e2574c" stroke="#333" stroke-width="5"/>
<rect x="289" y="94" width="22" height="18" rx="3" fill="#8fd0ff" stroke="#1d1a2b" stroke-width="3"/><circle cx="296" cy="102" r="2" fill="#1d1a2b"/><circle cx="304" cy="102" r="2" fill="#1d1a2b"/>
</g>
<text x="40" y="395" font-family="Caveat, cursive" font-size="34" fill="#fff">${esc(L.art.tower)}</text>
</svg>`;
}

function familySVG(){
  const fig=(x,col,h,label,hair)=>`<g><circle cx="${x}" cy="${260-h}" r="22" fill="#ffe0c2" stroke="#8a5a33" stroke-width="4"/>${hair}<circle cx="${x-7}" cy="${258-h}" r="2.5" fill="#222"/><circle cx="${x+7}" cy="${258-h}" r="2.5" fill="#222"/><path d="M${x-8} ${268-h}q8 7 16 0" stroke="#222" stroke-width="3" fill="none"/><path d="M${x-22} ${284-h}h44l10 ${h-10}h-64z" fill="${col}" stroke="#333" stroke-width="4"/><path d="M${x-10} ${274}v46M${x+10} 274v46" stroke="#333" stroke-width="6"/><text x="${x}" y="360" text-anchor="middle" font-family="Caveat, cursive" font-size="30" fill="#333">${esc(label)}</text></g>`;
  return `<svg viewBox="0 0 600 420" xmlns="http://www.w3.org/2000/svg"><defs>${crayon('fcr',2,5)}</defs>
<rect width="600" height="420" fill="#fbfaf5"/>
<g filter="url(#fcr)" stroke-linecap="round" stroke-linejoin="round">
${fig(90,'#e2574c',150,L.art.famMom,`<path d="M68 105q22-30 44 0v30h-8v-22h-28v22h-8z" fill="#c9a25a"/>`)}
${fig(210,'#46a35a',180,L.art.famDad,`<path d="M190 70q20-20 40 0" stroke="#4a3320" stroke-width="8" fill="none"/>`)}
${fig(340,'#2b6fd6',110,L.art.famMe,`<path d="M318 140q10-25 22-24q18-2 22 20q-12-8-22-4q-12-6-22 8z" fill="#7a4a22"/>`)}
<g><path d="M470 150v-22" stroke="#1d1a2b" stroke-width="4"/><circle cx="470" cy="124" r="7" fill="#ff6b6b" stroke="#1d1a2b" stroke-width="3"/><rect x="438" y="150" width="64" height="52" rx="9" fill="#8fd0ff" stroke="#2d5f8a" stroke-width="5"/><circle cx="458" cy="172" r="5" fill="#1d1a2b"/><circle cx="482" cy="172" r="5" fill="#1d1a2b"/><path d="M456 186q14 10 28 0" stroke="#1d1a2b" stroke-width="4" fill="none"/><rect x="446" y="206" width="48" height="66" rx="5" fill="#c8b8ff" stroke="#5a3db8" stroke-width="5"/><path d="M458 272v48M482 272v48" stroke="#333" stroke-width="6"/><text x="470" y="360" text-anchor="middle" font-family="Caveat, cursive" font-size="30" fill="#333">${esc(L.art.famPix)}</text></g>
<path d="M366 200h72" stroke="#ffcfa5" stroke-width="7"/>
</g>
<text x="300" y="50" text-anchor="middle" font-family="Caveat, cursive" font-size="42" fill="#3a2f8f">${esc(L.art.famTitle)}</text>
</svg>`;
}

/* Рисунок для настоящего финала: вся семья вместе, маяк выключен. */
function newWallSVG(){
  const kid=(x,col,y,s,hair)=>`<g transform="translate(${x} ${y}) scale(${s})"><circle cx="0" cy="0" r="30" fill="#ffe0c2" stroke="#8a5a33" stroke-width="5"/>${hair}<circle cx="-10" cy="-2" r="3.5" fill="#222"/><circle cx="10" cy="-2" r="3.5" fill="#222"/><path d="M-11 11q11 10 22 0" stroke="#222" stroke-width="4" fill="none"/><path d="M-28 34h56l12 110h-80z" fill="${col}" stroke="#333" stroke-width="5"/><path d="M-12 144v70M12 144v70" stroke="#333" stroke-width="8"/></g>`;
  return `<svg viewBox="0 0 1200 800" preserveAspectRatio="xMidYMid slice" xmlns="http://www.w3.org/2000/svg" aria-hidden="true"><defs>${crayon('nwcr',11,7)}</defs>
<rect width="1200" height="800" fill="#cfeaff"/>
<g filter="url(#nwcr)" stroke-linecap="round" stroke-linejoin="round">
 <circle cx="1030" cy="140" r="70" fill="#ffd23f" stroke="#e39b00" stroke-width="6"/>
 <path d="M1030 40v-26M1030 240v26M930 140h-26M1130 140h26" stroke="#e39b00" stroke-width="7"/>
 <path d="M0 560Q300 500 600 540T1200 520L1200 800L0 800Z" fill="#86d36f" stroke="#4f9e3d" stroke-width="6"/>
 <path d="M60 800C120 740 260 720 420 700L420 800Z" fill="#5aa9e6" stroke="#2f78b8" stroke-width="5"/>
 <path d="M160 540L172 390L200 390L212 540Z" fill="#efe9df" stroke="#777" stroke-width="5"/>
 <rect x="166" y="362" width="40" height="30" fill="#6b7080" stroke="#777" stroke-width="5"/>
 <path d="M160 362L186 334L212 362Z" fill="#a9a9a9" stroke="#777" stroke-width="5"/>
 <path d="M560 250L660 180L760 250V380H560Z" fill="#f5d9a8" stroke="#8a5a33" stroke-width="6"/>
 <path d="M540 255L660 165L780 255" fill="none" stroke="#c9372f" stroke-width="12"/>
 <rect x="640" y="300" width="40" height="80" fill="#8a5a33"/>
 <rect x="585" y="280" width="36" height="34" fill="#fff27a" stroke="#8a5a33" stroke-width="4"/><rect x="700" y="280" width="36" height="34" fill="#fff27a" stroke="#8a5a33" stroke-width="4"/>
 ${kid(470,'#e2574c',470,1,`<path d="M-32 -6q32-44 64 0v40h-10v-30h-44v30h-10z" fill="#c9a25a"/>`)}
 ${kid(620,'#2b6fd6',520,.8,`<path d="M-30 -8q12-32 30-30q26-3 30 28q-16-12-30-6q-16-8-30 8z" fill="#7a4a22"/>`)}
 ${kid(770,'#46a35a',455,1.08,`<path d="M-28 -20q28-26 56 0" stroke="#4a3320" stroke-width="10" fill="none"/>`)}
 <path d="M494 530L596 560M644 560L744 520" stroke="#ffcfa5" stroke-width="10"/>
</g>
<text x="560" y="735" font-family="Caveat, Comic Sans MS, cursive" font-size="84" fill="#3a2f8f">${esc(L.art.newWall)}</text>
<text x="70" y="300" font-family="Caveat, Comic Sans MS, cursive" font-size="32" fill="#3a2f8f">${esc(L.art.newWallSub)}</text>
</svg>`;
}

function camSVG(){
  const s=state.stage;
  const mom = s===2 ? `<g opacity=".92"><path d="M360 300q-4-40 20-52q-14-16-2-34q16-18 34-2q12 16-2 34q26 12 22 54z" fill="#050508"/><path d="M372 300q30 8 58 0" stroke="#050508" stroke-width="10"/></g>` : '';
  const glow = s>=3 ? `<rect x="360" y="70" width="120" height="90" fill="#ff2a2a" opacity=".12"/><rect x="398" y="98" width="12" height="12" fill="#ff3b30" opacity=".55"/><rect x="430" y="98" width="12" height="12" fill="#ff3b30" opacity=".55"/>` : '';
  const dark = s>=3 ? `<rect width="640" height="400" fill="#000" opacity=".55"/>` : '';
  return `<svg viewBox="0 0 640 400" preserveAspectRatio="xMidYMid slice" xmlns="http://www.w3.org/2000/svg">
<rect width="640" height="400" fill="#15161d"/>
<rect x="60" y="60" width="140" height="150" fill="#1f2d4d" stroke="#2a2c38" stroke-width="10"/><path d="M130 60v150M60 135h140" stroke="#2a2c38" stroke-width="7"/>
<circle cx="170" cy="92" r="12" fill="#c8cbd6" opacity=".55"/>
<rect x="0" y="330" width="640" height="70" fill="#0e0f14"/>
<rect x="300" y="290" width="300" height="50" fill="#262838"/><rect x="300" y="250" width="40" height="50" fill="#2b2d3f"/><rect x="330" y="280" width="260" height="20" fill="#34364a"/>
<path d="M470 285q40-20 90 0" fill="#4a3a6a" opacity=".6"/>
${mom}
<rect x="230" y="270" width="18" height="90" fill="#1d1e28"/><rect x="190" y="250" width="60" height="16" fill="#23242f"/><rect x="200" y="170" width="46" height="84" rx="4" fill="#1c1d27"/>
<rect x="520" y="120" width="90" height="70" fill="#1a1b24"/><path d="M530 175l20-30l14 18l10-10l26 22z" fill="#23283a"/>
${dark}${glow}
</svg>`;
}
