const jwt = require('jsonwebtoken');

// İstemciden (uygulamadan) gelen istekteki JWT (JSON Web Token) kimliğini doğrulayan ara katman.
// Token geçerliyse içindeki kullanıcı verisini çözüp req.user içerisine yerleştirir.
function authenticate(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Token bulunamadı' });
  }

  const token = header.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch {
    res.status(401).json({ message: 'Geçersiz veya süresi dolmuş token' });
  }
}

// Belirli rotalara sadece izin verilen rollerin (admin, restaurant_owner vb.) erişmesini sağlayan koruma katmanı.
function authorize(...roles) {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ message: 'Bu işlem için yetkiniz yok' });
    }
    next();
  };
}

module.exports = { authenticate, authorize };