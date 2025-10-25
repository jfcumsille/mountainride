const defaultTheme = require('tailwindcss/defaultTheme')
const { execSync } = require('child_process')

// Get ActiveAdmin gem path
const activeAdminPath = execSync('bundle show activeadmin', { encoding: 'utf-8' }).trim()

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}',
    './app/admin/**/*.{arb,erb,html,rb}',
    `${activeAdminPath}/app/views/**/*.{arb,erb,html,rb}`,
    `${activeAdminPath}/vendor/javascript/flowbite.js`,
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
    require(`${activeAdminPath}/plugin.js`),
  ]
}
