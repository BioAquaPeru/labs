// Supabase Edge Function; deploy sin verify_jwt para permitir QR públicos.
// El acceso al documento requiere un token aleatorio de 256 bits y estado activo.
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const headers={'Content-Type':'application/json; charset=utf-8','Access-Control-Allow-Origin':'*','Access-Control-Allow-Methods':'GET, OPTIONS','Access-Control-Allow-Headers':'apikey, authorization, content-type','Cache-Control':'no-store'};
serve(async(req)=>{
 if(req.method==='OPTIONS')return new Response(null,{status:204,headers});
 if(req.method!=='GET')return new Response(JSON.stringify({error:'Método no permitido'}),{status:405,headers});
 const token=new URL(req.url).searchParams.get('token')||'';
 if(!/^[a-f0-9]{64}$/.test(token))return new Response(JSON.stringify({error:'Código inválido'}),{status:400,headers});
 try {
  const db=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false,autoRefreshToken:false}});
  const {data,error}=await db.from('portal_reports').select('number,identification,published_at,issuer,file_path,status').eq('token',token).maybeSingle();
  if(error)throw error;
  if(!data||data.status!=='active')return new Response(JSON.stringify({error:'Informe no disponible'}),{status:404,headers});
  const {data:signed,error:signError}=await db.storage.from('report-pdfs').createSignedUrl(data.file_path,60,{download:true});
  if(signError)throw signError;
  return new Response(JSON.stringify({number:data.number,identification:data.identification,published_at:data.published_at,issuer:data.issuer,download_url:signed.signedUrl}),{headers});
 }catch(err){console.error(err);return new Response(JSON.stringify({error:'No se pudo cargar el informe'}),{status:500,headers})}
});
