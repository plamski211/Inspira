# Inspira - Pinterest-Inspired Multimedia Platform

Inspira is a modern, responsive multimedia sharing platform inspired by Pinterest's design and functionality. It allows users to discover, save, and share creative content in a visually engaging interface.

## Features

- Responsive masonry grid layout for content display
- Modern navigation system with intuitive UI
- Interactive pin cards with hover effects
- Detailed pin view with comments and related content
- User profiles with customizable settings
- Content upload and management
- Dark mode support

## Tech Stack

- React 18
- Vite
- React Router
- Tailwind CSS
- Framer Motion
- Lucide React (icons)

## Getting Started

### Prerequisites

- Node.js (v18+)
- npm or yarn

### Installation

1. Clone the repository
   \`\`\`bash
   git clone https://github.com/yourusername/inspira.git
   cd inspira
   \`\`\`

2. Install dependencies
   \`\`\`bash
   npm install
   \`\`\`

3. Start the development server
   \`\`\`bash
   npm run dev
   \`\`\`

4. Open your browser and navigate to http://localhost:3000

## Project Structure

\`\`\`
src/
  assets/           # Static assets like images, fonts
  components/
    ui/             # Reusable UI components
    layout/         # Layout components (Header, Footer, etc.)
    features/       # Feature-specific components
  contexts/         # React contexts for state management
  hooks/            # Custom React hooks
  pages/            # Page components
  services/         # API services and external integrations
  utils/            # Utility functions
  styles/           # Global styles and theme configuration
\`\`\`

## Available Scripts

- `npm run dev` - Start the development server
- `npm run build` - Build for production
- `npm run preview` - Preview the production build
- `npm run lint` - Run ESLint
- `npm run format` - Format code with Prettier

## Performance Optimizations

This project includes several performance optimizations:

1. **Component Memoization**: React.memo is used to prevent unnecessary re-renders
2. **Image Optimization**: Lazy loading and responsive images
3. **Code Splitting**: Dynamic imports for route-based code splitting
4. **Virtualized Lists**: Efficient rendering of large lists
5. **Performance Monitoring**: Custom hooks for monitoring component performance

## Accessibility

Accessibility is a priority in this project:

1. **Semantic HTML**: Proper use of semantic elements
2. **ARIA Attributes**: Appropriate ARIA roles and attributes
3. **Keyboard Navigation**: Full keyboard support
4. **Screen Reader Support**: Text alternatives and proper labeling
5. **Color Contrast**: WCAG 2.1 AA compliant color contrast

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- Design inspiration from Pinterest
- Icons from Lucide React
- Animation library from Framer Motion
