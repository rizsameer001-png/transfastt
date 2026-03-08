import { useState, useEffect, useRef } from 'react';
import { adminAPI } from '../../utils/api';
import { Check, X, Eye, ChevronLeft, ChevronRight, FileText, ZoomIn,
         ExternalLink, Upload, Trash2, Plus, RefreshCw } from 'lucide-react';
import toast from 'react-hot-toast';

const StatusBadge = ({ status }) => {
  const s = {
    pending:      'bg-yellow-100 text-yellow-700',
    under_review: 'bg-blue-100   text-blue-700',
    approved:     'bg-green-100  text-green-700',
    rejected:     'bg-red-100    text-red-700',
  };
  return <span className={`badge ${s[status] || 'bg-gray-100 text-gray-600'}`}>{status?.replace('_', ' ')}</span>;
};

// ── Cloudinary doc card with lightbox ──────────────────────────────────────
function DocCard({ label, doc, onReplace, replacing }) {
  const [zoomed, setZoomed] = useState(false);
  const inputRef = useRef(null);
  const url    = doc?.url;
  const isPDF  = url?.includes('/raw/') || url?.toLowerCase().endsWith('.pdf');

  return (
    <>
      <div className="border border-gray-200 rounded-xl overflow-hidden group">
        {url ? (
          isPDF ? (
            <a href={url} target="_blank" rel="noreferrer"
              className="w-full h-28 flex flex-col items-center justify-center gap-2
                         bg-red-50 hover:bg-red-100 transition-colors block">
              <FileText size={26} className="text-red-400" />
              <span className="text-xs text-gray-500 flex items-center gap-1">Open PDF <ExternalLink size={10} /></span>
            </a>
          ) : (
            <button type="button" onClick={() => setZoomed(true)} className="w-full relative block">
              <img src={url} alt={label} className="w-full h-28 object-cover" />
              <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors
                              flex items-center justify-center">
                <ZoomIn size={20} className="text-white opacity-0 group-hover:opacity-100 transition-opacity" />
              </div>
            </button>
          )
        ) : (
          <div className="w-full h-28 flex items-center justify-center bg-gray-50">
            <span className="text-xs text-gray-300">Not uploaded</span>
          </div>
        )}

        <div className="px-2.5 py-2 bg-white border-t border-gray-100 flex items-center gap-1.5">
          <span className="text-xs font-semibold text-gray-500 truncate flex-1">{label}</span>
          {url && <Check size={11} className="text-green-500 flex-shrink-0" />}
          {/* Admin replace button */}
          {onReplace && (
            <>
              <input ref={inputRef} type="file" accept="image/jpeg,image/png,application/pdf"
                className="hidden" onChange={e => onReplace(e.target.files[0])} />
              <button onClick={() => inputRef.current.click()} disabled={replacing}
                className="p-1 rounded-lg hover:bg-gray-100 text-gray-400 hover:text-primary-600
                           transition-colors flex-shrink-0" title="Replace document">
                {replacing
                  ? <div className="w-3 h-3 border border-primary-600 border-t-transparent rounded-full animate-spin" />
                  : <RefreshCw size={12} />}
              </button>
            </>
          )}
        </div>
      </div>

      {zoomed && url && !isPDF && (
        <div className="fixed inset-0 bg-black/85 z-[200] flex items-center justify-center p-4"
          onClick={() => setZoomed(false)}>
          <button className="absolute top-5 right-5 w-10 h-10 rounded-full bg-white/15
                             flex items-center justify-center hover:bg-white/25"
            onClick={() => setZoomed(false)}>
            <X size={20} className="text-white" />
          </button>
          <img src={url} alt={label}
            className="max-w-full max-h-[88vh] rounded-2xl shadow-2xl object-contain"
            onClick={e => e.stopPropagation()} />
          <span className="absolute bottom-6 left-1/2 -translate-x-1/2
                           bg-black/40 text-white text-sm px-4 py-1.5 rounded-full">
            {label}
          </span>
        </div>
      )}
    </>
  );
}

// ── Admin Upload Panel ─────────────────────────────────────────────────────
function AdminUploadPanel({ kyc, onDocAdded, onDocDeleted }) {
  const inputRef  = useRef(null);
  const [label, setLabel]     = useState('');
  const [note, setNote]       = useState('');
  const [file, setFile]       = useState(null);
  const [uploading, setUploading] = useState(false);
  const [deletingId, setDeletingId] = useState(null);

  const handleUpload = async () => {
    if (!file || !label.trim()) { toast.error('Please pick a file and add a label'); return; }
    setUploading(true);
    try {
      const fd = new FormData();
      fd.append('document', file);
      fd.append('label', label.trim());
      if (note.trim()) fd.append('note', note.trim());
      const res = await adminAPI.uploadKycDoc(kyc._id, fd);
      toast.success('Document uploaded');
      onDocAdded(res.data.kyc.adminDocuments);
      setFile(null); setLabel(''); setNote('');
    } catch (err) {
      toast.error(err.response?.data?.message || 'Upload failed');
    }
    setUploading(false);
  };

  const handleDelete = async (docId) => {
    if (!confirm('Delete this document?')) return;
    setDeletingId(docId);
    try {
      await adminAPI.deleteKycDoc(kyc._id, docId);
      toast.success('Document deleted');
      onDocDeleted(docId);
    } catch { toast.error('Delete failed'); }
    setDeletingId(null);
  };

  const isPDF = (url) => url?.includes('/raw/') || url?.endsWith('.pdf');

  return (
    <div className="space-y-4">
      {/* Existing admin docs */}
      {kyc.adminDocuments?.length > 0 && (
        <div className="space-y-2">
          <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide">Admin Uploaded Docs</p>
          {kyc.adminDocuments.map(doc => (
            <div key={doc._id}
              className="flex items-center gap-3 p-3 bg-blue-50 border border-blue-100 rounded-xl">
              {/* Thumbnail */}
              <div className="w-12 h-12 rounded-lg overflow-hidden flex-shrink-0 border border-blue-200">
                {isPDF(doc.url)
                  ? <div className="w-full h-full flex items-center justify-center bg-red-50">
                      <FileText size={18} className="text-red-400" />
                    </div>
                  : <img src={doc.url} alt={doc.label} className="w-full h-full object-cover" />
                }
              </div>
              {/* Info */}
              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold text-gray-800 truncate">{doc.label}</p>
                {doc.note && <p className="text-xs text-gray-500 truncate">{doc.note}</p>}
                <p className="text-xs text-gray-400">{new Date(doc.uploadedAt).toLocaleDateString()}</p>
              </div>
              {/* Actions */}
              <div className="flex items-center gap-1.5 flex-shrink-0">
                <a href={doc.url} target="_blank" rel="noreferrer"
                  className="p-1.5 rounded-lg hover:bg-blue-100 text-blue-500 transition-colors">
                  <ExternalLink size={14} />
                </a>
                <button onClick={() => handleDelete(doc._id)} disabled={deletingId === doc._id}
                  className="p-1.5 rounded-lg hover:bg-red-100 text-red-400 hover:text-red-600 transition-colors">
                  {deletingId === doc._id
                    ? <div className="w-3.5 h-3.5 border border-red-400 border-t-transparent rounded-full animate-spin" />
                    : <Trash2 size={14} />}
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Upload form */}
      <div className="border border-dashed border-gray-200 rounded-xl p-4 space-y-3">
        <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide flex items-center gap-1.5">
          <Plus size={12} /> Add Document
        </p>
        <input className="input-field text-sm" placeholder="Document label (e.g. Bank Statement) *"
          value={label} onChange={e => setLabel(e.target.value)} />
        <input className="input-field text-sm" placeholder="Note (optional)"
          value={note} onChange={e => setNote(e.target.value)} />
        <input ref={inputRef} type="file" accept="image/jpeg,image/png,application/pdf"
          className="hidden"
          onChange={e => setFile(e.target.files[0] || null)} />

        {file ? (
          <div className="flex items-center gap-2 p-2.5 bg-gray-50 rounded-lg">
            <FileText size={16} className="text-gray-400 flex-shrink-0" />
            <span className="text-xs text-gray-600 truncate flex-1">{file.name}</span>
            <span className="text-xs text-gray-400">{(file.size / 1024).toFixed(0)} KB</span>
            <button onClick={() => setFile(null)} className="p-0.5 hover:text-red-500">
              <X size={14} />
            </button>
          </div>
        ) : (
          <button onClick={() => inputRef.current.click()}
            className="w-full py-2.5 border border-dashed border-gray-300 rounded-lg text-sm
                       text-gray-400 hover:border-primary-400 hover:text-primary-500 transition-colors
                       flex items-center justify-center gap-2">
            <Upload size={14} /> Pick file (JPG, PNG or PDF · max 10 MB)
          </button>
        )}

        <button onClick={handleUpload} disabled={uploading || !file || !label.trim()}
          className="btn-primary w-full flex items-center justify-center gap-2 text-sm py-2.5
                     disabled:opacity-50 disabled:cursor-not-allowed">
          {uploading
            ? <><div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" /> Uploading…</>
            : <><Upload size={14} /> Upload to Cloudinary</>}
        </button>
      </div>
    </div>
  );
}

// ── KYC Detail Modal ───────────────────────────────────────────────────────
function KYCDetailModal({ kyc: initialKyc, onClose, onAction }) {
  const [kyc, setKyc]         = useState(initialKyc);
  const [reason, setReason]   = useState('');
  const [acting, setActing]   = useState(null);
  const [replacing, setReplacing] = useState({}); // { fieldName: bool }
  const [activeTab, setActiveTab] = useState('docs'); // 'docs' | 'admin'

  useEffect(() => setKyc(initialKyc), [initialKyc]);
  if (!kyc) return null;

  const handleAction = async (action) => {
    if (action === 'reject' && !reason.trim()) {
      toast.error('Please provide a rejection reason'); return;
    }
    setActing(action);
    await onAction(kyc._id, action, reason);
    setActing(null);
    onClose();
  };

  const handleReplaceDoc = async (field, file) => {
    if (!file) return;
    setReplacing(r => ({ ...r, [field]: true }));
    try {
      const fd = new FormData();
      fd.append('document', file);
      fd.append('field', field);
      const res = await adminAPI.replaceKycDoc(kyc._id, fd);
      setKyc(prev => ({ ...prev, [field]: res.data.document }));
      toast.success(`${field} replaced`);
    } catch (err) {
      toast.error(err.response?.data?.message || 'Replace failed');
    }
    setReplacing(r => ({ ...r, [field]: false }));
  };

  const docFields = [
    { label: 'ID Front',         key: 'idFrontImage'   },
    { label: 'ID Back',          key: 'idBackImage'    },
    { label: 'Selfie',           key: 'selfieImage'    },
    { label: 'Proof of Address', key: 'proofOfAddress' },
  ];
  const uploadedCount = docFields.filter(d => kyc[d.key]?.url).length;

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl w-full max-w-2xl max-h-[92vh] overflow-y-auto shadow-2xl">

        {/* Header */}
        <div className="sticky top-0 bg-white px-6 py-4 border-b border-gray-100
                        flex items-center justify-between z-10">
          <div className="flex items-center gap-3">
            <h2 className="text-xl font-bold text-gray-900">KYC Review</h2>
            <StatusBadge status={kyc.status} />
          </div>
          <button onClick={onClose} className="p-2 rounded-xl hover:bg-gray-100"><X size={18} /></button>
        </div>

        <div className="p-6 space-y-5">

          {/* Applicant */}
          <div className="bg-gray-50 rounded-xl p-4">
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3">Applicant</p>
            <div className="grid grid-cols-2 gap-3 text-sm">
              <div><p className="text-gray-400 text-xs mb-0.5">Full Name</p>
                   <p className="font-semibold">{kyc.user?.firstName} {kyc.user?.lastName}</p></div>
              <div><p className="text-gray-400 text-xs mb-0.5">Email</p>
                   <p className="font-semibold text-primary-700">{kyc.user?.email}</p></div>
              <div><p className="text-gray-400 text-xs mb-0.5">Country</p>
                   <p className="font-semibold">{kyc.user?.country}</p></div>
              <div><p className="text-gray-400 text-xs mb-0.5">Nationality</p>
                   <p className="font-semibold">{kyc.nationality}</p></div>
            </div>
          </div>

          {/* Details grid */}
          <div className="grid grid-cols-2 gap-3 text-sm">
            {[
              { l: 'Date of Birth',   v: kyc.dateOfBirth ? new Date(kyc.dateOfBirth).toLocaleDateString('en-US', { year:'numeric', month:'long', day:'numeric' }) : '—' },
              { l: 'Occupation',      v: kyc.occupation  || '—' },
              { l: 'ID Type',         v: kyc.idType?.replace('_', ' ') },
              { l: 'ID Number',       v: kyc.idNumber },
              { l: 'Source of Funds', v: kyc.sourceOfFunds },
              { l: 'ID Expiry',       v: kyc.idExpiryDate ? new Date(kyc.idExpiryDate).toLocaleDateString() : '—' },
            ].map(({ l, v }) => (
              <div key={l} className="bg-gray-50 rounded-xl p-3">
                <p className="text-gray-400 text-xs mb-1">{l}</p>
                <p className="font-semibold capitalize">{v}</p>
              </div>
            ))}
          </div>

          {/* Address */}
          {kyc.address && (
            <div className="bg-gray-50 rounded-xl p-4 text-sm">
              <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">Address</p>
              <p>{kyc.address.street}</p>
              <p>{kyc.address.city}{kyc.address.state ? `, ${kyc.address.state}` : ''} {kyc.address.postalCode}</p>
              <p className="font-semibold">{kyc.address.country}</p>
            </div>
          )}

          {/* Tabs: User docs / Admin docs */}
          <div>
            <div className="flex gap-1 p-1 bg-gray-100 rounded-xl mb-4">
              <button onClick={() => setActiveTab('docs')}
                className={`flex-1 text-sm font-semibold py-1.5 rounded-lg transition-colors
                  ${activeTab === 'docs' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-700'}`}>
                User Documents
                <span className={`ml-2 text-xs px-1.5 py-0.5 rounded-full
                  ${uploadedCount === 4 ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'}`}>
                  {uploadedCount}/4
                </span>
              </button>
              <button onClick={() => setActiveTab('admin')}
                className={`flex-1 text-sm font-semibold py-1.5 rounded-lg transition-colors
                  ${activeTab === 'admin' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-700'}`}>
                Admin Documents
                {kyc.adminDocuments?.length > 0 && (
                  <span className="ml-2 text-xs bg-blue-100 text-blue-700 px-1.5 py-0.5 rounded-full">
                    {kyc.adminDocuments.length}
                  </span>
                )}
              </button>
            </div>

            {activeTab === 'docs' && (
              <div className="grid grid-cols-2 gap-3">
                {docFields.map(({ label, key }) => (
                  <DocCard key={key} label={label} doc={kyc[key]}
                    onReplace={(file) => handleReplaceDoc(key, file)}
                    replacing={replacing[key]} />
                ))}
              </div>
            )}

            {activeTab === 'admin' && (
              <AdminUploadPanel
                kyc={kyc}
                onDocAdded={(docs) => setKyc(prev => ({ ...prev, adminDocuments: docs }))}
                onDocDeleted={(docId) => setKyc(prev => ({
                  ...prev,
                  adminDocuments: prev.adminDocuments.filter(d => d._id !== docId),
                }))}
              />
            )}
          </div>

          {/* Rejection input */}
          {kyc.status === 'under_review' && (
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                Rejection Reason <span className="text-gray-400 font-normal">(required if rejecting)</span>
              </label>
              <textarea rows={2} className="input-field resize-none"
                placeholder="e.g. ID expired, selfie doesn't match..."
                value={reason} onChange={e => setReason(e.target.value)} />
            </div>
          )}

          {kyc.status === 'rejected' && kyc.rejectedReason && (
            <div className="bg-red-50 border border-red-100 rounded-xl p-4">
              <p className="text-xs font-semibold text-red-600 mb-1">Rejection Reason</p>
              <p className="text-sm text-red-700">{kyc.rejectedReason}</p>
            </div>
          )}

          {kyc.submittedAt && (
            <p className="text-xs text-gray-400">Submitted: {new Date(kyc.submittedAt).toLocaleString()}</p>
          )}
        </div>

        {/* Action footer */}
        {kyc.status === 'under_review' && (
          <div className="sticky bottom-0 bg-white px-6 py-4 border-t border-gray-100 flex gap-3">
            <button onClick={() => handleAction('reject')} disabled={!!acting}
              className="btn-danger flex-1 flex items-center justify-center gap-2">
              {acting === 'reject'
                ? <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                : <X size={16} />}
              Reject
            </button>
            <button onClick={() => handleAction('approve')} disabled={!!acting}
              className="btn-primary flex-1 flex items-center justify-center gap-2">
              {acting === 'approve'
                ? <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                : <Check size={16} />}
              Approve
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

// ── Main Admin KYC Page ────────────────────────────────────────────────────
export default function AdminKYC() {
  const [kycList, setKycList]       = useState([]);
  const [loading, setLoading]       = useState(true);
  const [filters, setFilters]       = useState({ status: 'under_review', page: 1 });
  const [pagination, setPagination] = useState({ total: 0, pages: 1 });
  const [selected, setSelected]     = useState(null);

  const load = async () => {
    setLoading(true);
    try {
      const res = await adminAPI.getKYCList({ ...filters, limit: 15 });
      setKycList(res.data.kycList);
      setPagination(res.data.pagination);
    } catch {}
    setLoading(false);
  };

  useEffect(() => { load(); }, [filters]);

  const handleAction = async (id, action, reason) => {
    try {
      await adminAPI.reviewKYC(id, { action, reason });
      toast.success(`KYC ${action}d successfully`);
      load();
    } catch (err) {
      toast.error(err.response?.data?.message || 'Action failed');
    }
  };

  return (
    <div className="space-y-5 animate-fade-in">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">KYC Review</h1>
        <p className="text-sm text-gray-500 mt-1">Review, upload, and approve identity verification submissions</p>
      </div>

      <div className="card py-4">
        <div className="flex items-center gap-3">
          <select className="input-field sm:w-52 text-sm" value={filters.status}
            onChange={e => setFilters(f => ({ ...f, status: e.target.value, page: 1 }))}>
            <option value="">All Submissions</option>
            <option value="under_review">Under Review</option>
            <option value="approved">Approved</option>
            <option value="rejected">Rejected</option>
          </select>
          <span className="text-sm text-gray-400 ml-auto">
            {pagination.total} submission{pagination.total !== 1 ? 's' : ''}
          </span>
        </div>
      </div>

      <div className="card overflow-hidden p-0">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-100">
              <tr>
                {['Applicant','ID Type','Source of Funds','Docs','Admin Docs','Submitted','Status','Action'].map(h => (
                  <th key={h} className="text-left text-xs font-semibold text-gray-500 px-4 py-3.5">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {loading ? (
                [1,2,3].map(i => (
                  <tr key={i}><td colSpan={8} className="px-4 py-4">
                    <div className="h-8 bg-gray-100 rounded animate-pulse" />
                  </td></tr>
                ))
              ) : kycList.length === 0 ? (
                <tr><td colSpan={8} className="text-center py-12 text-gray-400">No KYC submissions found</td></tr>
              ) : kycList.map(kyc => {
                const docCount   = ['idFrontImage','idBackImage','selfieImage','proofOfAddress'].filter(k => kyc[k]?.url).length;
                const adminCount = kyc.adminDocuments?.length || 0;
                return (
                  <tr key={kyc._id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-3.5">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 bg-blue-100 rounded-full flex items-center justify-center
                                        text-blue-700 font-bold text-sm flex-shrink-0">
                          {kyc.user?.firstName?.[0]}{kyc.user?.lastName?.[0]}
                        </div>
                        <div>
                          <p className="font-semibold text-gray-800 text-sm">{kyc.user?.firstName} {kyc.user?.lastName}</p>
                          <p className="text-xs text-gray-400">{kyc.user?.email}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3.5 text-sm text-gray-600 capitalize">{kyc.idType?.replace('_',' ')}</td>
                    <td className="px-4 py-3.5 text-sm text-gray-600 capitalize">{kyc.sourceOfFunds}</td>
                    <td className="px-4 py-3.5">
                      <span className={`inline-flex items-center gap-1 text-xs font-semibold px-2 py-1 rounded-full
                        ${docCount === 4 ? 'bg-green-100 text-green-700' : docCount > 0 ? 'bg-yellow-100 text-yellow-700' : 'bg-gray-100 text-gray-500'}`}>
                        {docCount > 0 && <Check size={10} />}{docCount}/4
                      </span>
                    </td>
                    <td className="px-4 py-3.5">
                      {adminCount > 0
                        ? <span className="inline-flex items-center gap-1 text-xs font-semibold px-2 py-1 rounded-full bg-blue-100 text-blue-700">
                            <FileText size={10} />{adminCount}
                          </span>
                        : <span className="text-xs text-gray-300">—</span>}
                    </td>
                    <td className="px-4 py-3.5 text-sm text-gray-500">
                      {kyc.submittedAt ? new Date(kyc.submittedAt).toLocaleDateString() : '—'}
                    </td>
                    <td className="px-4 py-3.5"><StatusBadge status={kyc.status} /></td>
                    <td className="px-4 py-3.5">
                      <button onClick={() => setSelected(kyc)}
                        className="flex items-center gap-1.5 text-sm text-primary-600 hover:text-primary-800 font-medium">
                        <Eye size={14} /> Review
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        {pagination.pages > 1 && (
          <div className="flex items-center justify-between px-5 py-3 border-t border-gray-100">
            <p className="text-sm text-gray-500">Total: {pagination.total}</p>
            <div className="flex items-center gap-2">
              <button onClick={() => setFilters(f => ({ ...f, page: f.page - 1 }))}
                disabled={filters.page === 1} className="p-1.5 rounded-lg hover:bg-gray-100 disabled:opacity-40">
                <ChevronLeft size={16} />
              </button>
              <span className="text-sm font-medium">{filters.page} / {pagination.pages}</span>
              <button onClick={() => setFilters(f => ({ ...f, page: f.page + 1 }))}
                disabled={filters.page === pagination.pages} className="p-1.5 rounded-lg hover:bg-gray-100 disabled:opacity-40">
                <ChevronRight size={16} />
              </button>
            </div>
          </div>
        )}
      </div>

      <KYCDetailModal kyc={selected} onClose={() => setSelected(null)} onAction={handleAction} />
    </div>
  );
}
