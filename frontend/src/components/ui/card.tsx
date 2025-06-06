export function Card({ children, className = "" }) {
  return <div className={`bg-white rounded-2xl shadow p-4 flex flex-col ${className}`}>{children}</div>
}

export function CardHeader({ children, className = "" }) {
  return <div className={`mb-2 ${className}`}>{children}</div>
}

export function CardContent({ children, className = "" }) {
  return <div className={`flex-1 ${className}`}>{children}</div>
}

export function CardFooter({ children, className = "" }) {
  return <div className={`mt-2 text-sm text-gray-500 ${className}`}>{children}</div>
}
