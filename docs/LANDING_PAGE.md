# Landing Page Setup

This repository uses [docsify](https://docsify.js.org/) to generate a beautiful landing page from the README.md file. The landing page is automatically deployed to GitHub Pages.

## 🌐 Live Site

The landing page is available at: [https://ai-tools.itman.fyi](https://ai-tools.itman.fyi)

## 🚀 How It Works

1. **Docsify**: A lightweight documentation generator that renders Markdown files on-the-fly
   - No build process required
   - Renders README.md as the main page
   - Includes search functionality
   - Syntax highlighting for code blocks

2. **GitHub Pages**: Automatic deployment via GitHub Actions
   - Triggers on push to `main` branch
   - Deploys all files to GitHub Pages
   - Custom domain configured via CNAME file

## 📁 Key Files

- `index.html` - Docsify configuration and entry point
- `.nojekyll` - Tells GitHub Pages not to use Jekyll processing
- `.github/workflows/deploy-pages.yml` - GitHub Actions workflow for deployment
- `CNAME` - Custom domain configuration

## 🎨 Features

- ✅ Automatic README rendering
- ✅ Full-text search
- ✅ Syntax highlighting (bash, json, yaml, markdown)
- ✅ Copy code button
- ✅ Image zoom
- ✅ Mobile responsive
- ✅ Edit on GitHub link
- ✅ GitHub repository link

## 🔧 Local Testing

To test the landing page locally:

```bash
# Install a local web server (pick one)
npm install -g docsify-cli
# OR
python -m http.server 3000

# For docsify-cli
docsify serve .

# For Python
# Then visit http://localhost:3000
```

## 📝 Customization

### Changing the Theme

Edit `index.html` and change the theme link:

```html
<!-- Available themes: vue, buble, dark, pure -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/docsify@4/lib/themes/vue.css">
```

### Adding Pages

1. Create new Markdown files in the repository
2. Link to them from README.md
3. Docsify will automatically render them

### Sidebar Navigation

To enable sidebar navigation, create `_sidebar.md` and set `loadSidebar: true` in `index.html`.

## 🔗 Resources

- [Docsify Documentation](https://docsify.js.org/)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Custom Domain Setup](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site)
