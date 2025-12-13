import { useEffect, useState } from 'react'
import { clearStats, getStats } from '../lib/api'

export default function PanelHome(){
  const [stats, setStats] = useState<{publications:number; editions:number; users_active:number}>({publications:0, editions:0, users_active:0})
  const [loading, setLoading] = useState(false)
  const load = ()=> getStats().then(setStats).catch(()=>setStats({publications:0, editions:0, users_active:0}))
  useEffect(()=>{ load() },[])
  const onClear = async()=>{
    if (!confirm('¿Seguro que deseas borrar todas las publicaciones, ediciones y pagos? Esta acción no se puede deshacer.')) return
    setLoading(true)
    try { const r = await clearStats(); setStats(r) } finally { setLoading(false) }
  }
  const cards = [
    {t:'Publicaciones', v:String(stats.publications)},
    {t:'Ediciones', v:String(stats.editions)},
    {t:'Usuarios activos', v:String(stats.users_active)},
  ]
  return (
    <section className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold">Inicio</h1>
          <p className="text-sm text-slate-600">Resumen rápido y accesos a las secciones clave.</p>
        </div>
        <button className="btn btn-ghost" onClick={onClear} disabled={loading}>{loading? 'Limpiando...' : 'Limpiar datos'}</button>
      </div>
      <div className="grid md:grid-cols-3 gap-4">
        {cards.map((c)=> (
          <div key={c.t} className="card p-4">
            <div className="text-sm text-slate-500">{c.t}</div>
            <div className="text-3xl font-semibold text-brand-800">{c.v}</div>
          </div>
        ))}
      </div>
      <div className="grid md:grid-cols-3 gap-4">
        <a href="/dashboard/publicaciones" className="card p-4 hover:shadow transition">
          <div className="text-sm text-slate-500">Gestión</div>
          <div className="text-lg font-semibold">Publicaciones</div>
          <div className="text-xs text-slate-500 mt-1">Revisa y actualiza el estado.</div>
        </a>
        <a href="/dashboard/ediciones" className="card p-4 hover:shadow transition">
          <div className="text-sm text-slate-500">Editorial</div>
          <div className="text-lg font-semibold">Ediciones</div>
          <div className="text-xs text-slate-500 mt-1">Organiza órdenes por edición.</div>
        </a>
        <a href="/dashboard/usuarios" className="card p-4 hover:shadow transition">
          <div className="text-sm text-slate-500">Administración</div>
          <div className="text-lg font-semibold">Usuarios</div>
          <div className="text-xs text-slate-500 mt-1">Gestiona cuentas y roles.</div>
        </a>
      </div>
    </section>
  )
}
