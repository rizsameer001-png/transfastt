import { useState, useEffect, useRef } from 'react';
import { useAuth } from '../../context/AuthContext';
import { kycAPI } from '../../utils/api';
import toast from 'react-hot-toast';
import { Shield, Check, Clock, AlertCircle, Upload, X, FileText, ExternalLink } from 'lucide-react';

// ── File upload box ────────────────────────────────────────────────────────
function FileUploadBox({ label, fieldName, file, onFileChange, onRemove, required }) {
  const inputRef = useRef(null);
  const [preview, setPreview] = useState(null);
  const isImage = file?.type?.startsWith('image/');
  const isPDF   = file?.type === 'application/pdf';

  useEffect(() => {
    if (!file || !isImage) { setPreview(null); return; }
    const url = URL.createObjectURL(file);
    setPreview(url);
    return () => URL.revokeObjectURL(url);
  }, [file]);

  const handlePick = (e) => {
    const picked = e.target.files[0];
    if (!picked) return;
    if (picked.size > 5 * 1024 * 1024) {
      toast.error(`${label}: file must be under 5 MB`); return;
    }
    onFileChange(fieldName, picked);
    e.target.value = '';
  };

  return (
    <div className="space-y-1.5">
      <label className="block text-xs font-semibold text-gray-600 uppercase tracking-wide">
        {label}{required && <span className="text-red-500 ml-0.5">*</span>}
      </label>
      <input ref={inputRef} type="file" accept="image/jpeg,image/png,application/pdf"
        className="hidden" onChange={handlePick} />

      {!file ? (
        <button type="button" onClick={() => inputRef.current.click()}
          className="w-full h-28 border-2 border-dashed border-gray-200 rounded-xl
                     flex flex-col items-center justify-center gap-2
                     hover:border-primary-400 hover:bg-primary-50 transition-all group">
          <Upload size={22} className="text-gray-300 group-hover:text-primary-500 transition-colors" />
          <span className="text-xs text-gray-400 group-hover:text-primary-500">Click to upload</span>
          <span className="text-xs text-gray-300">JPG · PNG · PDF — max 5 MB</span>
        </button>
      ) : (
        <div className="relative border border-gray-200 rounded-xl overflow-hidden bg-gray-50">
          {isImage && preview
            ? <img src={preview} alt={label} className="w-full h-28 object-cover" />
            : isPDF
            ? <div className="w-full h-28 flex flex-col items-center justify-center gap-2 bg-red-50">
                <FileText size={28} className="text-red-400" />
                <span className="text-xs text-gray-600 font-medium px-4 truncate max-w-full">{file.name}</span>
              </div>
            : <div className="w-full h-28 flex items-center justify-center">
                <span className="text-xs text-gray-400">{file.name}</span>
              </div>
          }
          <button type="button" onClick={() => onRemove(fieldName)}
            className="absolute top-2 right-2 w-6 h-6 rounded-full bg-black/60
                       flex items-center justify-center hover:bg-red-600 transition-colors">
            <X size={12} className="text-white" />
          </button>
          <div className="px-3 py-1.5 bg-white border-t border-gray-100 flex items-center gap-1.5">
            <Check size={11} className="text-green-500 flex-shrink-0" />
            <span className="text-xs text-gray-600 truncate">{file.name}</span>
            <span className="text-xs text-gray-400 ml-auto">{(file.size / 1024).toFixed(0)} KB</span>
          </div>
        </div>
      )}
    </div>
  );
}

// ── Stored Cloudinary doc card ─────────────────────────────────────────────
function StoredDocCard({ label, doc }) {
  // doc = { url, publicId } or null
  const [zoomed, setZoomed] = useState(false);
  const url   = doc?.url;
  const isPDF = url?.includes('/raw/') || url?.endsWith('.pdf');

  return (
    <>
      <div className="border border-gray-100 rounded-xl overflow-hidden">
        {url ? (
          isPDF ? (
            <a href={url} target="_blank" rel="noreferrer"
              className="w-full h-28 flex flex-col items-center justify-center gap-2
                         bg-red-50 hover:bg-red-100 transition-colors cursor-pointer block">
              <FileText size={26} className="text-red-400" />
              <span className="text-xs text-gray-500 flex items-center gap-1">
                Open PDF <ExternalLink size={10} />
              </span>
            </a>
          ) : (
            <button type="button" onClick={() => setZoomed(true)} className="w-full group relative block">
              <img src={url} alt={label} className="w-full h-28 object-cover" />
              <div className="absolute inset-0 bg-black/0 group-hover:bg-black/25 transition-colors
                              flex items-center justify-center">
                <span className="text-white text-xs font-semibold opacity-0 group-hover:opacity-100">
                  Click to zoom
                </span>
              </div>
            </button>
          )
        ) : (
          <div className="w-full h-28 flex items-center justify-center bg-gray-50">
            <span className="text-xs text-gray-300">Not uploaded</span>
          </div>
        )}
        <div className="px-3 py-1.5 border-t border-gray-100 flex items-center gap-1.5">
          <span className="text-xs font-semibold text-gray-500">{label}</span>
          {url && <Check size={11} className="ml-auto text-green-500" />}
        </div>
      </div>

      {zoomed && url && !isPDF && (
        <div className="fixed inset-0 bg-black/85 z-[100] flex items-center justify-center p-4"
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

// ── Main KYC page ──────────────────────────────────────────────────────────
const EMPTY_FORM = {
  dateOfBirth: '', nationality: '', occupation: '',
  sourceOfFunds: 'employment', idType: 'passport',
  idNumber: '', idExpiryDate: '',
  address: { street: '', city: '', state: '', postalCode: '', country: '' },
};

export default function KYCPage() {
  const { user }              = useAuth();
  const [kyc, setKyc]         = useState(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [form, setForm]       = useState(EMPTY_FORM);
  const [files, setFiles]     = useState({
    idFrontImage: null, idBackImage: null,
    selfieImage: null, proofOfAddress: null,
  });

  useEffect(() => {
    kycAPI.getStatus()
      .then(r => {
        setKyc(r.data.kyc);
        if (r.data.kyc) {
          const k = r.data.kyc;
          setForm({
            dateOfBirth:   k.dateOfBirth   ? k.dateOfBirth.split('T')[0]   : '',
            nationality:   k.nationality   || '',
            occupation:    k.occupation    || '',
            sourceOfFunds: k.sourceOfFunds || 'employment',
            idType:        k.idType        || 'passport',
            idNumber:      k.idNumber      || '',
            idExpiryDate:  k.idExpiryDate  ? k.idExpiryDate.split('T')[0] : '',
            address:       k.address       || EMPTY_FORM.address,
          });
        }
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const u  = (f, v) => setForm(p => ({ ...p, [f]: v }));
  const ua = (f, v) => setForm(p => ({ ...p, address: { ...p.address, [f]: v } }));
  const handleFileChange = (field, file) => setFiles(f => ({ ...f, [field]: file }));
  const handleRemove     = (field)       => setFiles(f => ({ ...f, [field]: null }));

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!files.idFrontImage && !kyc?.idFrontImage?.url) {
      toast.error('ID Front image is required'); return;
    }
    if (!files.selfieImage && !kyc?.selfieImage?.url) {
      toast.error('Selfie image is required'); return;
    }

    setSubmitting(true);
    try {
      const fd = new FormData();
      fd.append('dateOfBirth',   form.dateOfBirth);
      fd.append('nationality',   form.nationality);
      fd.append('occupation',    form.occupation);
      fd.append('sourceOfFunds', form.sourceOfFunds);
      fd.append('idType',        form.idType);
      fd.append('idNumber',      form.idNumber);
      if (form.idExpiryDate) fd.append('idExpiryDate', form.idExpiryDate);
      fd.append('address', JSON.stringify(form.address));
      if (files.idFrontImage)   fd.append('idFrontImage',   files.idFrontImage);
      if (files.idBackImage)    fd.append('idBackImage',    files.idBackImage);
      if (files.selfieImage)    fd.append('selfieImage',    files.selfieImage);
      if (files.proofOfAddress) fd.append('proofOfAddress', files.proofOfAddress);

      await kycAPI.submit(fd);
      //toast.success('KYC submitted! We'll review it within 1-2 business days.');
      toast.success("KYC submitted! We'll review it within 1-2 business days");
      const r = await kycAPI.getStatus();
      setKyc(r.data.kyc);
      setFiles({ idFrontImage: null, idBackImage: null, selfieImage: null, proofOfAddress: null });
    } catch (err) {
      toast.error(err.response?.data?.message || 'Submission failed. Please try again.');
    }
    setSubmitting(false);
  };

  const StatusBanner = () => {
    const status = kyc?.status || user?.kycStatus || 'pending';
    const cfgs = {
      approved:     { bg: 'bg-green-50  border-green-200',  Icon: Check,       color: 'text-green-600',  title: 'KYC Approved',          msg: 'Your identity is verified. You can now send money internationally.' },
      under_review: { bg: 'bg-blue-50   border-blue-200',   Icon: Clock,       color: 'text-blue-600',   title: 'Under Review',          msg: 'Your documents are being reviewed. This usually takes 1-2 business days.' },
      submitted:    { bg: 'bg-blue-50   border-blue-200',   Icon: Clock,       color: 'text-blue-600',   title: 'Submitted',             msg: 'Your KYC is submitted and awaiting admin review.' },
      rejected:     { bg: 'bg-red-50    border-red-200',    Icon: AlertCircle, color: 'text-red-600',    title: 'KYC Rejected',          msg: kyc?.rejectedReason || 'Please fix the issues and resubmit your documents.' },
      pending:      { bg: 'bg-yellow-50 border-yellow-200', Icon: Shield,      color: 'text-yellow-600', title: 'Verification Required', msg: 'Submit your documents to unlock international money transfers.' },
    };
    const c = cfgs[status] ?? cfgs.pending;
    return (
      <div className={`border rounded-2xl p-5 flex items-start gap-4 ${c.bg}`}>
        <div className={`w-11 h-11 rounded-xl flex items-center justify-center bg-white flex-shrink-0 ${c.color}`}>
          <c.Icon size={20} />
        </div>
        <div>
          <p className={`font-bold text-sm ${c.color}`}>{c.title}</p>
          <p className="text-sm text-gray-600 mt-0.5">{c.msg}</p>
        </div>
      </div>
    );
  };

  if (loading) return (
    <div className="flex items-center justify-center h-64">
      <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary-600" />
    </div>
  );

  const currentStatus = kyc?.status || user?.kycStatus || 'pending';
  const canSubmit = ['pending', 'rejected'].includes(currentStatus);
  const docFields = [
    { label: 'ID Front',         key: 'idFrontImage'   },
    { label: 'ID Back',          key: 'idBackImage'    },
    { label: 'Selfie',           key: 'selfieImage'    },
    { label: 'Proof of Address', key: 'proofOfAddress' },
  ];

  return (
    <div className="max-w-2xl mx-auto space-y-6 animate-fade-in">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">KYC Verification</h1>
        <p className="text-sm text-gray-500 mt-1">Verify your identity to send money internationally</p>
      </div>

      <StatusBanner />

      {/* Read-only submitted docs */}
      {kyc && ['under_review', 'submitted', 'approved'].includes(kyc.status) && (
        <div className="card space-y-4">
          <h2 className="font-bold text-gray-900">Submitted Documents</h2>
          <div className="grid grid-cols-2 gap-3">
            {docFields.map(({ label, key }) => (
              <StoredDocCard key={key} label={label} doc={kyc[key]} />
            ))}
          </div>
        </div>
      )}

      {/* Submission form */}
      {canSubmit && (
        <form onSubmit={handleSubmit} className="card space-y-6">

          {/* Personal info */}
          <section>
            <h2 className="font-bold text-gray-900 text-lg mb-4">Personal Information</h2>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">Date of Birth <span className="text-red-500">*</span></label>
                  <input type="date" required className="input-field" value={form.dateOfBirth} onChange={e => u('dateOfBirth', e.target.value)} />
                </div>
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">Nationality <span className="text-red-500">*</span></label>
                  <input required className="input-field" placeholder="e.g. American" value={form.nationality} onChange={e => u('nationality', e.target.value)} />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">Occupation</label>
                  <input className="input-field" placeholder="Your occupation" value={form.occupation} onChange={e => u('occupation', e.target.value)} />
                </div>
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">Source of Funds <span className="text-red-500">*</span></label>
                  <select required className="input-field" value={form.sourceOfFunds} onChange={e => u('sourceOfFunds', e.target.value)}>
                    <option value="employment">Employment</option>
                    <option value="business">Business</option>
                    <option value="savings">Savings</option>
                    <option value="investment">Investment</option>
                    <option value="inheritance">Inheritance</option>
                    <option value="other">Other</option>
                  </select>
                </div>
              </div>
            </div>
          </section>

          <hr className="border-gray-100" />

          {/* Identity document */}
          <section>
            <h2 className="font-bold text-gray-900 text-lg mb-4">Identity Document</h2>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">ID Type <span className="text-red-500">*</span></label>
                  <select required className="input-field" value={form.idType} onChange={e => u('idType', e.target.value)}>
                    <option value="passport">Passport</option>
                    <option value="national_id">National ID</option>
                    <option value="drivers_license">Driver's License</option>
                    <option value="residence_permit">Residence Permit</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">ID Number <span className="text-red-500">*</span></label>
                  <input required className="input-field" placeholder="Document number" value={form.idNumber} onChange={e => u('idNumber', e.target.value)} />
                </div>
              </div>
              <div className="w-1/2">
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">ID Expiry Date</label>
                <input type="date" className="input-field" value={form.idExpiryDate} onChange={e => u('idExpiryDate', e.target.value)} />
              </div>
            </div>
          </section>

          <hr className="border-gray-100" />

          {/* Document uploads */}
          <section>
            <h2 className="font-bold text-gray-900 text-lg mb-1">Document Uploads</h2>
            <p className="text-sm text-gray-400 mb-4">
              JPG, PNG or PDF · Max 5 MB ·
              <span className="text-red-500"> ID Front</span> and
              <span className="text-red-500"> Selfie</span> are required
            </p>

            {/* Previously uploaded docs on rejection */}
            {kyc?.status === 'rejected' && docFields.some(d => kyc[d.key]?.url) && (
              <div className="mb-4 p-3 bg-yellow-50 border border-yellow-200 rounded-xl">
                <p className="text-xs font-semibold text-yellow-700 mb-2">
                  Previously uploaded (kept unless you replace them)
                </p>
                <div className="grid grid-cols-4 gap-2">
                  {docFields.map(({ label, key }) => (
                    <div key={key} className="text-center">
                      {kyc[key]?.url ? (
                        <img src={kyc[key].url} alt={label}
                          className="w-full h-14 object-cover rounded-lg border border-yellow-200" />
                      ) : (
                        <div className="w-full h-14 flex items-center justify-center bg-gray-50
                                        rounded-lg border border-dashed border-gray-200">
                          <span className="text-xs text-gray-300">—</span>
                        </div>
                      )}
                      <p className="text-xs text-gray-400 mt-1">{label}</p>
                    </div>
                  ))}
                </div>
              </div>
            )}

            <div className="grid grid-cols-2 gap-4">
              <FileUploadBox label="ID Front"         fieldName="idFrontImage"   required file={files.idFrontImage}   onFileChange={handleFileChange} onRemove={handleRemove} />
              <FileUploadBox label="ID Back"          fieldName="idBackImage"             file={files.idBackImage}    onFileChange={handleFileChange} onRemove={handleRemove} />
              <FileUploadBox label="Selfie"           fieldName="selfieImage"    required file={files.selfieImage}    onFileChange={handleFileChange} onRemove={handleRemove} />
              <FileUploadBox label="Proof of Address" fieldName="proofOfAddress"          file={files.proofOfAddress} onFileChange={handleFileChange} onRemove={handleRemove} />
            </div>
          </section>

          <hr className="border-gray-100" />

          {/* Address */}
          <section>
            <h2 className="font-bold text-gray-900 text-lg mb-4">Residential Address</h2>
            <div className="space-y-3">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">Street Address <span className="text-red-500">*</span></label>
                <input required className="input-field" placeholder="123 Main Street" value={form.address.street} onChange={e => ua('street', e.target.value)} />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">City <span className="text-red-500">*</span></label>
                  <input required className="input-field" placeholder="New York" value={form.address.city} onChange={e => ua('city', e.target.value)} />
                </div>
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">State / Province</label>
                  <input className="input-field" placeholder="NY" value={form.address.state} onChange={e => ua('state', e.target.value)} />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">Postal Code</label>
                  <input className="input-field" placeholder="10001" value={form.address.postalCode} onChange={e => ua('postalCode', e.target.value)} />
                </div>
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">Country <span className="text-red-500">*</span></label>
                  <input required className="input-field" placeholder="United States" value={form.address.country} onChange={e => ua('country', e.target.value)} />
                </div>
              </div>
            </div>
          </section>

          <button type="submit" disabled={submitting}
            className="btn-primary w-full py-3.5 flex items-center justify-center gap-2 text-base">
            {submitting
              ? <><div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" /> Uploading & Submitting...</>
              : <><Shield size={17} /> Submit KYC Documents</>}
          </button>
        </form>
      )}
    </div>
  );
}
