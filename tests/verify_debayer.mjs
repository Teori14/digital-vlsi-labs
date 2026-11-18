import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

function referenceRgb(b,n){var result=[];var p=(r,c)=>r<0||c<0||r>=n||c>=n?0:b[r*n+c];for(var r=0;r<n;r++)for(var c=0;c<n;c++){var known=p(r,c),rEven=r%2===0,cEven=c%2===0;var axial=(p(r-1,c)+p(r+1,c)+p(r,c-1)+p(r,c+1))>>2;var diagonal=(p(r-1,c-1)+p(r-1,c+1)+p(r+1,c-1)+p(r+1,c+1))>>2;var vertical=(p(r-1,c)+p(r+1,c))>>1;var horizontal=(p(r,c-1)+p(r,c+1))>>1;result.push(rEven?(cEven?[vertical,known,horizontal]:[diagonal,axial,known]):(cEven?[known,axial,diagonal]:[horizontal,known,vertical]));}return result;}

const root = fileURLToPath(new URL('../', import.meta.url));
const input = readFileSync(path.join(root, 'tests/fixtures/input_pixels.txt'), 'utf8').trim().split(/\s+/).map(Number);
const outputPath = process.argv[2] ? path.resolve(process.argv[2]) : path.join(root, 'evidence/debayer-4x4/dut_rgb.txt');
const actual = readFileSync(outputPath, 'utf8').trim().split(/\r?\n/).map(line => line.trim().split(/\s+/).map(Number));
const expected = referenceRgb(input, 4);
if (input.length !== 16 || actual.length !== 16 || actual.some(row => row.length !== 3 || row.some(v => !Number.isInteger(v) || v < 0 || v > 255))) {
  throw new Error('Expected 16 input pixels and 16 RGB output rows.');
}
let mismatches = 0;
for (let i = 0; i < expected.length; i++) {
  for (let c = 0; c < 3; c++) {
    if (actual[i][c] !== expected[i][c]) {
      console.error('Mismatch:', { pixel: i, channel: c, actual: actual[i][c], expected: expected[i][c] });
      mismatches++;
    }
  }
}
console.log(JSON.stringify({ pixels: actual.length, channels: 48, mismatches, passed: mismatches === 0 }, null, 2));
if (mismatches) process.exitCode = 1;
