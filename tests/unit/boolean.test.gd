extends WAT.Test

func title():
	return "Given a Boolean Assertion"

func test_when_calling_asserts_is_true():
	describe("When calling asserts.is_true(true)")
	
	asserts.is_true(true, "Then it passes")
	
func test_when_calling_asserts_is_false():
	describe("When calling asserts.is_false(false)")
	
	asserts.is_false(false, "Then it passes")
	

