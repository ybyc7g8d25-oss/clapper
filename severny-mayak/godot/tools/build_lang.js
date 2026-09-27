// Собирает lang/src/*.js (удобно редактировать, можно писать комментарии) в lang/*.json для Godot.
// Запуск из папки godot/:  node tools/build_lang.js
const vm = require('vm'), fs = require('fs'), path = require('path');
const root = path.join(__dirname, '..');
const c = {}; c.window = c; vm.createContext(c);
for (const l of ['ru', 'en']) vm.runInContext(fs.readFileSync(path.join(root, 'lang/src', l + '.js'), 'utf8'), c);
const fix = v => typeof v === 'string' ? v.replace(/<br>/g, '\n').replace(/<b>/g, '[b]').replace(/<\/b>/g, '[/b]')
  : Array.isArray(v) ? v.map(fix) : v && typeof v === 'object' ? Object.fromEntries(Object.entries(v).map(([k, x]) => [k, fix(x)])) : v;
// проверка: у обоих языков одинаковая структура
let bad = 0;
(function walk(a, b, p) {
  if (typeof a !== typeof b || Array.isArray(a) !== Array.isArray(b)) { console.log('type mismatch', p); bad++; return; }
  if (Array.isArray(a)) { if (a.length !== b.length && !/answers/.test(p)) { console.log('length mismatch', p, a.length, b.length); bad++; } a.forEach((x, i) => b[i] !== undefined && walk(x, b[i], p + '[' + i + ']')); return; }
  if (a && typeof a === 'object') for (const k of new Set([...Object.keys(a), ...Object.keys(b)])) { if (!(k in a) || !(k in b)) { console.log('missing key', p + '.' + k); bad++; continue; } walk(a[k], b[k], p + '.' + k); }
})(c.SM_LANG.ru, c.SM_LANG.en, '');
for (const l of ['ru', 'en']) fs.writeFileSync(path.join(root, 'lang', l + '.json'), JSON.stringify(fix(c.SM_LANG[l]), null, 1));
console.log(bad ? `lang built with ${bad} mismatches` : 'lang ok');
process.exit(bad ? 1 : 0);
