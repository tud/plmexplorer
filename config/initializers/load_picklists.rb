CAGE_CODES = DynList.build_from('IPD_BUSINESSID', :bdesc)

CHANGE_CLASSES = DynList.build_from('IPD_CHNGCLASS', :bdesc)

CHANGE_SUBCLASSES = DynList.build_from('IPD_CHNGSUBCLASS', :bdesc)

DOCUMENT_SIZES = DynList.build_from('IPD_DOCSIZE', :bdesc)

PROJECT_LIST = Bproject.find(:all).map { |prj| prj.bname }.sort
PROJECT_LIST.unshift('')

USER_LIST = Bdbuser.find(:all).map { |user| user.buser }.sort.uniq
USER_LIST.unshift('')
