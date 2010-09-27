ACTIVE_PROJECTS = Bproject.find(:all).map { |prj| prj.bname if (!prj.migrated? && !prj.obsolete?) }.compact.sort

ALTERNATE_LANGUAGE = [
  [ 'Default',                       '0' ],
  [ 'English Alternate Description', '1' ]
]

CAGE_CODES = DynList.build_from('IPD_BUSINESSID', :bdesc)

CHANGE_CLASSES = DynList.build_from('IPD_CHNGCLASS', :bdesc)

CHANGE_SUBCLASSES = DynList.build_from('IPD_CHNGSUBCLASS', :bdesc)

CHILDREN = YAML::load(File.open("#{RAILS_ROOT}/config/settings/children.yml"))

DATA_MATURITY = [
  'CURRENT',
  'RELEASED'
]

DOCUMENT_SIZES = DynList.build_from('IPD_DOCSIZE', :bdesc)

LOGISTIC_ITEMS = [
  [ 'Ricambio',              'R'  ],
  [ 'Dotazione',             'D'  ],
  [ 'Dotazione-Ricambio',    'DR' ],
  [ 'Attrezzatura',          'A'  ],
  [ 'Attrezzatura-Ricambio', 'AR' ]
]

MSG = YAML::load(File.open("#{RAILS_ROOT}/config/settings/messages.yml"))

FORMS = YAML::load(File.open("#{RAILS_ROOT}/config/settings/record_forms.yml"))

NAVIGATION = YAML::load(File.open("#{RAILS_ROOT}/config/settings/navigation.yml"))

ODM_TYPE = [
  'CHANGE',
  'CHANGE_LOG'
]

PARENTS = YAML::load(File.open("#{RAILS_ROOT}/config/settings/parents.yml"))

PREF = YAML::load(File.open("#{RAILS_ROOT}/config/settings/preferences.yml"))

PRINTERS = DynList.build_from('IPD_PRINTER', :bdesc)

PROJECT_LIST = Bproject.find(:all).map { |prj| prj.bname }.sort

PROPRIETARY_LEVELS = [
  [ '',
    [ 'TUTTI I DIRITTI RIS.',
      'RISER. INDUSTRIALE',
      'RIS.(PROD)SU LICENZA'
    ]
  ],
  [ '-----------------------------------',
    [ 'Unlimited Rights',
      'Limited Rights',
      'Restricted Rights',
      'Proprietary',
      'Company Private',
      'Sector Sensitive',
      'Licensed',
      'Government'
    ]
  ]
]

REASONS_FOR_CHANGE = [
  [ '',
    [ 'MODIFICA DI DISEGNAZIONE',
      'MODIF.DI PROGETTAZIONE ELETTRICA',
      'MODIF.DI PROGETTAZIONE MECCANICA',
      'MODIFICA DEI REQUISITI',
      'MIGLIORIA PRODOTTO/PRODUCIBILITA',
      'MODIFICA PER APPROVVIGIONAMENTO',
      'MODIFICA PER PRODUZIONE',
      'MODIFICA PER INDUSTRIALIZZAZIONE',
      'MODIFICA SOFTWARE'
    ]
  ],
  [ '-------------------------------------------------------',
    [ 'Drawing Error',
      'Design Error Electrical',
      'Design Error Mechanical',
      'Specification Error',
      'Requirements Change',
      'Improve Product/Producibility',
      'Procurement Change',
      'Manufacturing Change',
      'Developmental Change',
      'Software Problem',
      'Software Documentation Problem',
      'Software Design Problem'
    ]
  ]
]

RECORD_TYPE = [
  [ 'Part/Document', '0' ],
  [ 'Part',          '1' ]
]

REPORT_FORMAT = [
  'COMPLETO',
  'LISTA'
]

REPORT_PROGRESS = [
  'EVASE',
  'NON_EVASE',
  'TUTTE'
]

REQ_STATUS = [
  'APPROVED',
  'CREATED',
  'PROPOSE',
  'REJECTED',
  'REVIEW'
]

SECURITY_CLASSES = [
  [ '',
    [ 'NON_CLASSIFICATO',
      'RISERVATO',
      'RISERVATISSIMO',
      'RISERVATO_NATO',
      'RISERVATISSIMO_NATO',
      'SEGRETO'
    ]
  ],
  [ '------------------------------------',
    [ 'Confidential',
      'Unclassified',
      'Secret',
      'Top Secret',
      'COMSEC Confidential',
      'COMSEC Secret'
    ]
  ]
]

SORT_CRITERIA = [
  [ 'BREAKDOWN - Report order as Breakdown', 'BREAKDOWN' ],
  [ 'NUMERICAL - Report order as Numerical', 'NUMERICAL' ]
]

USER_LIST = Bdbuser.find(:all).map { |user| user.buser }.sort.uniq

WA_STATUS = [
  'CLOSED',
  'COMPLETE',
  'CREATED',
  'REJECTED'
]

WA_TYPE = [
  'CHANGE',
  'CHANGE_LOG',
  'TASK',
  'TASK_LOG'
]

YES_NO = [
  [ 'YES', 'Y' ],
  [ 'NO',  'N' ]
]

#################################################################################
# Le costanti sottostanti sono funzione delle precedenti
#################################################################################

APPL_RECTYPES = NAVIGATION['FIND'].map { |nav| nav['type'] } - ['GENERIC']
