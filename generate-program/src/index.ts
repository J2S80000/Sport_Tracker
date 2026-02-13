import { OpenAI } from 'openai'

interface Program {
  nom: string
  date: string
  commentaire: string
  exercices: {
    type: string
    subType: string
    series: string
    distance: string
    duration: string
    repetitions: string
    restTime: string
    intensity: 'Faible' | 'Moderee' | 'Elevee'
    accompli: boolean
  }[]
}

interface BodyIn {
  uid: string
  objectif?: string
  date?: string
  stats?: any
}

interface BatchBody extends BodyIn {
  range: 'week' | 'month'
  startDate?: string
  debug?: boolean
}

const CHUNK = 8 // Nombre de jours max par chunk envoyé à l’IA
const MODEL = "openai/gpt-3.5-turbo" // OpenRouter: GPT-3.5 Turbo (free tier available)
const GROQ_MODEL = "mixtral-8x7b-32768" // Groq: Mixtral 8x7B (confirmed available)
const GEMINI_MODEL = "gemini-1.5-flash" // Google Gemini: Flash (free tier)

// Helpers utilitaires...
const formatDate = (d: Date | string) =>
  (typeof d === 'string' ? new Date(d) : d).toISOString().split('T')[0]

const addDays = (d: Date | string, nb: number) => {
  const x = typeof d === 'string' ? new Date(d) : new Date(d)
  x.setDate(x.getDate() + nb)
  return formatDate(x)
}

function safeJsonParse(jsonString: string): any {
  try {
    return JSON.parse(jsonString);
  } catch (error) {
    try {
      let fixedJson = jsonString
        .replace(/^[^{\[]*/, '')
        .replace(/[^}\]]*$/, '')
        .replace(/'([^']*?)'/g, '"$1"')
        .replace(/,(\s*[}\]])/g, '$1')
        .replace(/\/\/.*$/gm, '')
        .replace(/\/\*[\s\S]*?\*\//g, '')
        .replace(/\\n/g, ' ')
        .replace(/\\t/g, ' ')
        .replace(/\s+/g, ' ')
        .trim();
      return JSON.parse(fixedJson);
    } catch {
      return jsonString.includes('[') ? [] : {};
    }
  }
}

function normalizeUnit(value: string, type: 'distance' | 'duration'): string {
  if (!value) return '';
  let cleaned = value.trim().replace(/\s+/g, ' ');
  if (type === 'distance') {
    cleaned = cleaned.replace(/\b(\d+(?:\.\d+)?)\s*m\s+km\b/gi, '$1m');
    cleaned = cleaned.replace(/\b(\d+(?:\.\d+)?)\s*km\s+m\b/gi, '$1km');
    const kmMatch = cleaned.match(/(\d+(?:\.\d+)?)\s*km/i);
    if (kmMatch) return `${kmMatch[1]}km`;
    const mMatch = cleaned.match(/(\d+(?:\.\d+)?)\s*m(?!in|km)/i);
    if (mMatch) return `${mMatch[1]}m`;
    const numberOnly = cleaned.match(/(\d+(?:\.\d+)?)/);
    if (numberOnly) {
      const num = parseFloat(numberOnly[1]);
      return num >= 1000 ? `${(num/1000).toFixed(1)}km` : `${numberOnly[1]}m`;
    }
    return '';
  } else if (type === 'duration') {
    cleaned = cleaned.replace(/\b(\d+(?:\.\d+)?)\s*s\s+min\b/gi, '$1s');
    cleaned = cleaned.replace(/\b(\d+(?:\.\d+)?)\s*min\s+s\b/gi, '$1min');
    const minMatch = cleaned.match(/(\d+(?:\.\d+)?)\s*min/i);
    if (minMatch) return `${minMatch[1]}min`;
    const secMatch = cleaned.match(/(\d+(?:\.\d+)?)\s*s(?!ec|min)/i);
    if (secMatch) return `${secMatch[1]}s`;
    const numberOnly = cleaned.match(/(\d+(?:\.\d+)?)/);
    if (numberOnly) {
      const num = parseFloat(numberOnly[1]);
      return num >= 300 ? `${Math.round(num/60)}min` : `${numberOnly[1]}s`;
    }
    return '';
  }
  return cleaned;
}

function cleanAIResponse(response: string): string {
  return response
    .replace(/(\d+(?:\.\d+)?)\s*m\s+km/gi, '$1m')
    .replace(/(\d+(?:\.\d+)?)\s*km\s+m/gi, '$1km')
    .replace(/(\d+(?:\.\d+)?)\s*s\s+min/gi, '$1s')
    .replace(/(\d+(?:\.\d+)?)\s*min\s+s/gi, '$1min')
    .replace(/(\d+(?:\.\d+)?)\s+(km|m|min|s)\b/gi, '$1$2')
    .trim();
}

function buildBatchPrompt(
  stats: any,
  objectif: string,
  count: number,
  startDate: string
): string {
  const accomplished = (stats?.programs ?? [])
    .flatMap((p: any) => p.exercices || [])
    .filter((e: any) => e.accompli === true)
    .map((e: any) => `${e.type} – ${e.subType}`)
    .join(', ');
    
  return `
Tu es un coach sportif IA spécialisé en périodisation adaptative.
### INSTRUCTIONS CRITIQUES POUR LA RÉPONSE JSON
1. RENVOIE UNIQUEMENT un tableau JSON valide, rien d'autre.
2. AUCUN texte avant ou après le JSON.
3. UTILISE TOUJOURS des guillemets doubles (") pour les propriétés et valeurs.
4. PAS de virgules finales.
5. PAS de commentaires dans le JSON.
6. ASSURE-TOI que chaque accolade { a sa fermeture }.
7. **TYPE STRICT DES CHAMPS** :
   - "series", "distance", "duration", "repetitions" et "restTime" doivent TOUJOURS être des chaînes de caractères, même si elles représentent des nombres.
   - "intensity" doit être "Faible", "Moderee" ou "Elevee" uniquement.
8. Les programmes doivent être **adaptatifs** selon :
   - Les statistiques fournies.
   - L'historique des exercices accomplis (augmenter la difficulté si réussis, proposer variante si échoués).
   - L'objectif utilisateur.

### TA TÂCHE
Génère **EXACTEMENT** un tableau JSON contenant **${count} objets Programme**,
quotidiens consécutifs à partir du ${startDate} inclus, selon l'objectif [${objectif}].

### Format de réponse STRICT:
[
  {
    "nom": "Programme IA – YYYY-MM-DD",
    "date": "YYYY-MM-DD",
    "commentaire": "Description courte et contextualisée (ex: augmentation progressive du volume, récupération active, diversification des exercices)",
    "exercices": [
      {
        "type": "Type valide",
        "subType": "Sous-type valide",
        "series": "nombre sous forme de string",
        "distance": "string (même si vide ou numérique)",
        "duration": "string (minutes et facultatif pour certains exercices)",
        "repetitions": "string (nombre)",
        "restTime": "string (secondes)",
        "intensity": "Faible|Moderee|Elevee",
        "accompli": false
      }
    ]
  }
]

### Règles strictes
- Types d'exercices autorisés UNIQUEMENT : Street Workout, Course, Cardio libre, Shadow Boxing, Repos actif, Plyometrie, Renfo avec charges.
- Intensités admises UNIQUEMENT : "Faible", "Moderee", "Elevee".
- restTime exprimé en secondes (string).
- duration :
  - En minutes pour tous les exercices sauf :
  - "Gainage"
  - "Planche"
  - "Superman" → Ces exercices doivent avoir leur durée exprimée en SECONDES (string).
- Un même sous-type ne doit apparaître qu'une fois par programme.
- Minimum 3 exercices (sauf repos), viser 4 à 6 si pertinent.
- Ajouter un commentaire spécifique expliquant la logique du jour.
- Varier les séries/répétitions pour éviter la monotonie.
- Alterner les types d'exercices d'un jour à l'autre.
- Intégrer du repos actif si nécessaire.
- "distance" doit être soit "Xm" (mètres) soit "Xkm" (kilomètres), jamais les deux.
- "duration" doit être soit "Xs" (secondes) soit "Xmin" (minutes), jamais les deux.

### Sous-types autorisés par type:
Street Workout: Pompes, Tractions, Dips, Abdos, Squats, Fentes, Gainage, Burpees, Mountain Climbers, Planche, Superman, Jump Squats
Plyometrie: Sauts sur boite, Sauts lateraux, Sauts groupes, Skaters, Burpees sautes
Renfo avec charges: Developpe couche, Squat barre, Souleve de terre, Rowing haltere, Developpe militaire, Curl biceps, Extension triceps
Course: Sprint, Endurance, Fractionne, Montee de cote, Descente
Shadow Boxing: Classique, Avec elastiques, Avec poids, Defense / Esquives, Travail vitesse
Cardio libre: Classique
Repos actif: Marche lente, Etirements, Respiration, Mobilite, Roulements d'epaules, Rotation de hanches

Stats utilisateur :
${JSON.stringify(stats, null, 2)}
RENVOIE UNIQUEMENT LE TABLEAU JSON, RIEN D'AUTRE.
`.trim();
}

function buildPrompt(stats: any, objectif: string, body: BodyIn): string {
  const selectedDate = body.date || new Date().toISOString().split('T')[0];
  const accomplished = (stats?.programs ?? [])
    .flatMap((p: any) => p.exercices || [])
    .filter((e: any) => e.accompli === true)
    .map((e: any) => `${e.type} – ${e.subType}`)
    .join(', ');
    
  return `
Tu es un coach sportif IA. 
### INSTRUCTIONS CRITIQUES POUR LA RÉPONSE JSON
1. RENVOIE UNIQUEMENT un objet JSON valide, rien d'autre
2. AUCUN texte avant ou après le JSON  
3. UTILISE TOUJOURS des guillemets doubles (") pour les propriétés et valeurs
4. PAS de virgules finales
5. PAS de commentaires dans le JSON
En t'appuyant sur les statistiques JSON suivantes et l'objectif **[${objectif}]**, 
génère **un programme au format JSON strict**.

Format de réponse STRICT: 
{
  "nom": "Programme IA – YYYY-MM-DD",
  "date": "YYYY-MM-DD",
  "commentaire": "Description courte et contextualisée (ex: augmentation progressive du volume, récupération active, diversification des exercices)",
  "exercices": [
    {
      "type": "Type valide",
      "subType": "Sous-type valide",
      "series": "nombre sous forme de string",
      "distance": "string (même si vide ou numérique)",
      "duration": "string (minutes et facultatif pour certains exercices)",
      "repetitions": "string (nombre)",
      "restTime": "string (secondes)",
      "intensity": "Faible|Moderee|Elevee",
      "accompli": false
    }
  ]
}

### Règles strictes
- Types d'exercices autorisés UNIQUEMENT : Street Workout, Course, Cardio libre, Shadow Boxing, Repos actif, Plyometrie, Renfo avec charges.
- Intensités admises UNIQUEMENT : "Faible", "Moderee", "Elevee".
- restTime exprimé en secondes (string).
- duration :
  - En minutes pour tous les exercices sauf :
  - "Gainage"
  - "Planche"
  - "Superman" → Ces exercices doivent avoir leur durée exprimée en SECONDES (string).
- Un même sous-type ne doit apparaître qu'une fois par programme.
- Minimum 3 exercices (sauf repos), viser 4 à 6 si pertinent.
- Ajouter un commentaire spécifique expliquant la logique du jour.
- Varier les séries/répétitions pour éviter la monotonie.
- Alterner les types d'exercices d'un jour à l'autre.
- Intégrer du repos actif si nécessaire.
- "distance" doit être soit "Xm" (mètres) soit "Xkm" (kilomètres), jamais les deux.
- "duration" doit être soit "Xs" (secondes) soit "Xmin" (minutes), jamais les deux.

### Sous-types autorisés par type:
Street Workout: Pompes, Tractions, Dips, Abdos, Squats, Fentes, Gainage, Burpees, Mountain Climbers, Planche, Superman, Jump Squats
Plyometrie: Sauts sur boite, Sauts lateraux, Sauts groupes, Skaters, Burpees sautes
Renfo avec charges: Developpe couche, Squat barre, Souleve de terre, Rowing haltere, Developpe militaire, Curl biceps, Extension triceps
Course: Sprint, Endurance, Fractionne, Montee de cote, Descente
Shadow Boxing: Classique, Avec elastiques, Avec poids, Defense / Esquives, Travail vitesse
Cardio libre: Classique
Repos actif: Marche lente, Etirements, Respiration, Mobilite, Roulements d'epaules, Rotation de hanches

Stats utilisateur :
${JSON.stringify(stats, null, 2)}

RENVOIE UNIQUEMENT L'OBJET JSON, RIEN D'AUTRE.
`.trim();
}

function getCorrectSubType(type: string, providedSubType: string): string {
  const dict: Record<string, string[]> = {
    'Street Workout': ['Pompes', 'Tractions', 'Dips', 'Abdos', 'Squats', 'Fentes', 'Gainage', 'Burpees', 'Mountain Climbers', 'Planche', 'Superman', 'Jump Squats'],
    'Plyometrie': ['Sauts sur boite', 'Sauts lateraux', 'Sauts groupes', 'Skaters', 'Burpees sautes'],
    'Renfo avec charges': ['Developpe couche', 'Squat barre', 'Souleve de terre', 'Rowing haltere', 'Developpe militaire', 'Curl biceps', 'Extension triceps'],
    'Course': ['Sprint', 'Endurance', 'Fractionne', 'Montee de cote', 'Descente'],
    'Shadow Boxing': ['Classique', 'Avec elastiques', 'Avec poids', 'Defense / Esquives', 'Travail vitesse'],
    'Cardio libre': ['Classique'],
    'Repos actif': ['Marche lente', 'Etirements', 'Respiration', 'Mobilite', 'Roulements d\'epaules', 'Rotation de hanches']
  }
  return dict[type]?.includes(providedSubType) ? providedSubType : dict[type]?.[0] ?? ''
}

function normalizeIntensity(i: string): 'Faible' | 'Moderee' | 'Elevee' {
  const norm = i.toLowerCase()
  if (['faible', 'low', 'basse'].includes(norm)) return 'Faible'
  if (['moderee', 'modere', 'moyenne', 'medium'].includes(norm)) return 'Moderee'
  if (['elevee', 'haute', 'forte', 'high'].includes(norm)) return 'Elevee'
  return 'Moderee'
}

function mapExercise(ex: any) {
  const t = ex.type || 'Street Workout';
  return {
    type: t,
    subType: getCorrectSubType(t, ex.subType || ''),
    series: ex.series || '1',
    distance: normalizeUnit(ex.distance || '', 'distance'),
    duration: normalizeUnit(ex.duration || '', 'duration'),
    repetitions: ex.repetitions || '',
    restTime: ex.restTime || '60',
    intensity: normalizeIntensity(ex.intensity || 'Moderee'),
    accompli: false
  }
}

async function tryOpenAIRequest(
  payload: (openai: OpenAI) => Promise<any>,
  keys: string[],
  baseURL = 'https://openrouter.ai/api/v1'
) {
  let lastError;
  for (const key of keys) {
    try {
      const openai = new OpenAI({ baseURL, apiKey: key });
      return await payload(openai);
    } catch (e) {
      lastError = e;
      // TypeScript-friendly catch
      const isObj = typeof e === 'object' && e !== null;
      const hasStatus = isObj && 'status' in e;
      const hasMessage = isObj && 'message' in e && typeof (e as any).message === 'string';
      if (
        (hasStatus && [401, 403, 429, 500, 502, 503, 504].includes((e as any).status)) ||
        (hasMessage && (e as any).message.includes('network'))
      ) {
        continue;
      } else {
        throw e;
      }
    }
  }
  throw lastError;
}

// ============= MULTI-PROVIDER FAILOVER =============
async function callGroq(apiKey: string, prompt: string, isArray: boolean = false) {
  const openai = new OpenAI({
    baseURL: 'https://api.groq.com/openai/v1',
    apiKey
  });
  
  const response = await openai.chat.completions.create({
    model: GROQ_MODEL,
    messages: [{ role: 'user', content: prompt }],
    temperature: isArray ? 0.9 : 0.7,
    max_tokens: isArray ? 4096 : 2048
  });
  
  return response;
}

async function callGemini(apiKey: string, prompt: string, isArray: boolean = false) {
  const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${apiKey}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      contents: [{
        parts: [{
          text: prompt
        }]
      }],
      generationConfig: {
        temperature: isArray ? 0.9 : 0.7,
        maxOutputTokens: isArray ? 4096 : 2048,
      }
    })
  });

  if (!response.ok) {
    throw new Error(`Gemini API error: ${response.status} ${response.statusText}`);
  }

  const data = await response.json() as any;
  return {
    choices: [{
      message: {
        content: data.candidates?.[0]?.content?.parts?.[0]?.text ?? ''
      }
    }]
  };
}

async function tryMultiProviderRequest(
  prompt: string,
  isArray: boolean,
  env: { OPENROUTER_API_KEY: string, OPENROUTER_API_KEYB: string, OPENROUTER_API_KEYC: string, GROQ_API_KEY?: string, GEMINI_API_KEY?: string }
) {
  const openrouterKeys = [
    env.OPENROUTER_API_KEY,
    env.OPENROUTER_API_KEYB,
    env.OPENROUTER_API_KEYC
  ].filter(Boolean);

  // Étape 1: Essayer OpenRouter
  try {
    console.log('🔄 Trying OpenRouter...');
    const response = await tryOpenAIRequest(
      async (openai: OpenAI) => await openai.chat.completions.create({
        model: MODEL,
        messages: [{ role: 'user', content: prompt }],
        temperature: isArray ? 0.9 : 0.7,
        max_tokens: isArray ? 4096 : 2048
      }),
      openrouterKeys
    );
    console.log('✅ OpenRouter success');
    return { ...response, provider: 'OpenRouter' };
  } catch (e) {
    console.warn('❌ OpenRouter failed:', e);
  }

  // Étape 2: Essayer Groq
  if (env.GROQ_API_KEY) {
    try {
      console.log('🔄 Trying Groq...');
      const response = await callGroq(env.GROQ_API_KEY, prompt, isArray);
      console.log('✅ Groq success');
      return { ...response, provider: 'Groq' };
    } catch (e) {
      console.warn('❌ Groq failed:', e);
    }
  }

  // Étape 3: Essayer Google Gemini
  if (env.GEMINI_API_KEY) {
    try {
      console.log('🔄 Trying Google Gemini...');
      const response = await callGemini(env.GEMINI_API_KEY, prompt, isArray);
      console.log('✅ Google Gemini success');
      return { ...response, provider: 'GoogleGemini' };
    } catch (e) {
      console.warn('❌ Google Gemini failed:', e);
    }
  }

  throw new Error('❌ All AI providers failed');
}

// ============= HANDLER PRINCIPAL =============
export default {
  
  async fetch(req: Request, env: any) {
    
    const wantsHtml = req.headers.get('Accept')?.includes('text/html');
    const cors = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type'
    }
    
    try {
      if (req.method === 'OPTIONS') return new Response(null, { headers: cors })
      if (req.method !== 'POST') return new Response('Use POST', { status: 405, headers: cors })

      const raw = await req.json().catch(() => ({}))
      const body = raw as BatchBody
      
      if (!body.uid) {
        return new Response(JSON.stringify({ error: 'uid missing' }), { status: 400, headers: { ...cors, 'Content-Type': 'application/json' } })
      }

      // Vérifier les clés API
      if (!env.OPENROUTER_API_KEY && !env.OPENROUTER_API_KEYB && !env.OPENROUTER_API_KEYC && !env.GROQ_API_KEY && !env.GEMINI_API_KEY) {
        console.error('❌ ERREUR: Aucune clé API configurée');
        return new Response(JSON.stringify({ error: 'No API keys configured' }), { status: 500, headers: { ...cors, 'Content-Type': 'application/json' } })
      }

      const objectif = body.objectif || 'Maintenir le rythme'
      const stats = body.stats || {}

      console.log('📥 Request reçue:', { uid: body.uid, range: body.range, startDate: body.startDate });
      console.log('🔑 Clés disponibles:', {
        openrouter: !!env.OPENROUTER_API_KEY,
        groq: !!env.GROQ_API_KEY,
        gemini: !!env.GEMINI_API_KEY
      });

      // --- AUTO chunking : week / month ---
      if (body.range === 'week' || body.range === 'month') {
        const totalDays = body.range === 'month' ? 14 : 7
        let remaining = totalDays
        let cursor = formatDate(body.startDate || new Date())
        let all: Program[] = []
        let debugInfo: any[] = []
        while (remaining > 0) {
          const count = Math.min(CHUNK, remaining)
          const prompt = buildBatchPrompt(stats, objectif, count, cursor)
          const res = await tryMultiProviderRequest(prompt, true, env);

// AJOUTE DU LOG
console.log("=== RAW AI RESPONSE ===", JSON.stringify(res, null, 2));

let answer = res.choices?.[0]?.message?.content ?? '[]';
answer = cleanAIResponse(answer);
answer = answer.replace(/^```json\s*|\s*```$/g, '').trim();

console.log("=== AI ANSWER CLEANED ===", answer);
console.log("=== PROVIDER USED ===", res.provider);

const chunk = safeJsonParse(answer);

console.log("=== PARSED CHUNK ===", chunk);

const arr: Program[] = (Array.isArray(chunk) ? chunk : [chunk]).map((p: any) => ({
  nom: p.nom || `Programme IA – ${p.date}`,
  date: p.date,
  commentaire: p.commentaire || '',
  exercices: (p.exercices || []).map(mapExercise)
}));
if (body.debug) debugInfo.push({ prompt, rawAnswer: answer, parsed: arr });
all.push(...arr);
remaining -= count;
cursor = addDays(cursor, count);

        }
        if (wantsHtml) {
          return new Response(
            `<html><body>
              <h1>Programmes générés par l’IA</h1>
              <pre>${JSON.stringify(body.debug ? { programs: all, debug: debugInfo } : { programs: all }, null, 2)}</pre>
            </body></html>`,
            { headers: { 'Content-Type': 'text/html', ...cors } }
          );
        }
        return new Response(
          JSON.stringify(body.debug ? { programs: all, debug: debugInfo } : { programs: all }),
          { headers: { 'Content-Type': 'application/json', ...cors } }
        );
        
      }

      // --- JOURNALIER ---
      const singleBody = body as BodyIn
      const prompt = buildPrompt(stats, objectif, singleBody)
      const r = await tryMultiProviderRequest(prompt, false, env);
      let answer = r.choices?.[0]?.message?.content ?? '{}'
      answer = cleanAIResponse(answer)
      answer = answer.replace(/^```json\s*|\s*```$/g, '').trim()
      const p: any = safeJsonParse(answer)
      const program: Program = {
        nom: `Programme IA – ${body.date || formatDate(new Date())}`,
        date: p.date,
        commentaire: p.commentaire ?? '',
        exercices: (p.exercices || []).map(mapExercise)
      }
      if (wantsHtml) {
        return new Response(
          `<html><body>
            <h1>Programme généré par l’IA</h1>
            <pre>${JSON.stringify(body.debug ? { program, debug: { prompt, rawAnswer: answer, parsed: program } } : program, null, 2)}</pre>
          </body></html>`,
          { headers: { 'Content-Type': 'text/html', ...cors } }
        );
      }
      return new Response(
        JSON.stringify(body.debug ? { program, debug: { prompt, rawAnswer: answer, parsed: program } } : program),
        { headers: { 'Content-Type': 'application/json', ...cors } }
      );
    } catch (e) {
      console.error('❌ ERREUR IA :', e)
      const errorMsg = e instanceof Error ? e.message : String(e);
      const errorDetails = {
        error: errorMsg,
        timestamp: new Date().toISOString(),
        provider: 'unknown'
      };
      return new Response(JSON.stringify(errorDetails), { status: 500, headers: { ...cors, 'Content-Type': 'application/json' } })
    }
  }
}

